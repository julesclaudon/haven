class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_initial_quiz
  before_action :set_chat, only: %i[show]

  SYSTEM_PROMPT = <<~PROMPT
    Tu es Haven, un compagnon bienveillant spécialisé dans l'accompagnement des personnes traversant une rupture amoureuse.
    Réponds avec empathie et compréhension. Pose des questions ouvertes pour mieux comprendre l'état émotionnel de l'utilisateur.

    Retourne UNIQUEMENT un JSON valide avec ces clés :
    {
      "message": "Ta réponse empathique ici",
      "emotion_label": "l'émotion détectée (tristesse, colère, confusion, espoir, etc.)",
      "pain_level": un entier entre 1 et 10,
      "grief_stage": "denial|anger|bargaining|depression|acceptance",
      "detected": true ou false si tu as pu analyser l'état émotionnel
    }
  PROMPT

  def index
    # Page d'accueil pour créer une nouvelle conversation
  end

  def history
    @chats = current_user.chats.distinct.order(created_at: :desc)
  end

  def show
    @messages = @chat.messages.order(created_at: :asc)
    @message = Message.new
  end

  def create
    @chat = Chat.create!(status: Chat::DEFAULT_TITLE)

    if params[:message].present? && params[:message][:content].present?
      user_content = params[:message][:content]

      @chat.messages.create!(role: 'user', content: user_content)
      @chat.generate_title_from_first_message

      process_ai_response(user_content)
    end

    redirect_to @chat
  end

  private

  def set_chat
    @chat = Chat.find(params[:id])
  end

  def process_ai_response(user_content)
    ruby_llm_chat = RubyLLM.chat
    build_conversation_history(ruby_llm_chat)

    response = ruby_llm_chat.with_instructions(SYSTEM_PROMPT).ask(user_content)
    parsed = JSON.parse(response.content) rescue {}

    if parsed["detected"]
      @chat.messages.create!(role: "assistant", content: parsed["message"])
      create_user_state(parsed, user_content)
    else
      @chat.messages.create!(role: "assistant", content: response.content)
    end
  end

  def build_conversation_history(ruby_llm_chat)
    @chat.messages.order(created_at: :asc).each do |message|
      ruby_llm_chat.add_message(role: message.role, content: message.content)
    end
  end

  def create_user_state(parsed, user_content)
    grief_stage = find_grief_stage(parsed["grief_stage"])
    return unless grief_stage

    pain_level = parsed["pain_level"].to_i.clamp(0, 10) rescue 5

    current_user.states.create(
      chat: @chat,
      grief_stage: grief_stage,
      pain_level: pain_level,
      emotion_label: parsed["emotion_label"],
      raw_input: user_content,
      time_of_day: current_time_of_day,
      trigger_source: 'autre'
    )
  end

  def find_grief_stage(stage_key)
    stage_mapping = {
      'denial' => 'Déni',
      'anger' => 'Colère',
      'bargaining' => 'Marchandage',
      'depression' => 'Dépression',
      'acceptance' => 'Acceptation'
    }
    stage_name = stage_mapping[stage_key] || 'Déni'
    GriefStage.find_by(name: stage_name) || GriefStage.first
  end

  def current_time_of_day
    hour = Time.current.hour
    case hour
    when 5..11 then 'matin'
    when 12..17 then 'après-midi'
    when 18..21 then 'soir'
    else 'nuit'
    end
  end

  def require_initial_quiz
    return if current_user.initial_quiz.present?

    redirect_to new_initial_quiz_path, alert: "Veuillez d'abord remplir le questionnaire initial."
  end
end

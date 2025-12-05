class ChatsController < ApplicationController
  include HavenPromptsHelper

  before_action :authenticate_user!
  before_action :require_initial_quiz
  before_action :set_chat, only: %i[show close]

  def index
    @chats = current_user.chats.order(created_at: :desc)
    @open_state_id = params[:open_state_id]
  end

  def new
    @chat = Chat.new
  end

  def show
    @messages = @chat.messages.order(created_at: :asc)
    @message = Message.new
  end

  def close
    @chat.close!
    run_analysis_prompt
    GenerateChatTitleJob.perform_later(@chat.id)
    last_state = @chat.states.last

    respond_to do |format|
      format.html { redirect_to chats_path(open_state_id: last_state&.id) }
      format.json { render json: { success: true, state_id: last_state&.id } }
    end
  end

  def create
    @chat = Chat.create!(status: Chat::DEFAULT_TITLE)

    # Créer un state initial pour lier l'utilisateur au chat
    initial_state = current_user.states.create!(
      chat: @chat,
      grief_stage: GriefStage.first,
      pain_level: current_user.initial_quiz&.pain_level || 5,
      raw_input: "",
      trigger_source: 'autre',
      time_of_day: current_time_of_day
    )

    if params[:message].present? && params[:message][:content].present?
      user_content = params[:message][:content]

      @chat.messages.create!(role: 'user', content: user_content)
      @chat.generate_title_from_first_message

      process_initial_response(user_content)
    end

    redirect_to @chat
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end

  # Premier message : utilise le prompt initial avec le contexte du formulaire
  def process_initial_response(user_content)
    ruby_llm_chat = RubyLLM.chat
    prompt = initial_prompt(current_user.initial_quiz)

    response = ruby_llm_chat.with_instructions(prompt).ask(user_content)
    response_content = response.content

    # Gestion de l'urgence
    if response_content.include?("[URGENCE]")
      handle_emergency_response
      return
    end

    @chat.messages.create!(role: "assistant", content: response_content)
  end

  # Prompt d'analyse déclenché à la fermeture
  def run_analysis_prompt
    last_state = @chat.states.last
    return unless last_state

    # Récupérer le score et profil précédents
    previous_analysis = current_user.states
                                    .joins(:analysis)
                                    .where.not(id: last_state.id)
                                    .order(created_at: :desc)
                                    .first&.analysis

    previous_score = previous_analysis&.score || 0
    previous_profile = current_user.archetype&.archetype_name

    # Construire l'historique de conversation
    conversation_history = @chat.messages.order(created_at: :asc).map do |msg|
      "#{msg.role == 'user' ? 'Utilisateur' : 'Haven'}: #{msg.content}"
    end.join("\n\n")

    ruby_llm_chat = RubyLLM.chat
    prompt = analysis_prompt(previous_score, previous_profile)

    response = ruby_llm_chat.with_instructions(prompt).ask(conversation_history)

    begin
      parsed = JSON.parse(response.content)
      save_analysis_results(last_state, parsed, previous_score)
    rescue JSON::ParserError
      Rails.logger.error("Erreur parsing analyse: #{response.content}")
    end
  end

  def save_analysis_results(state, parsed, previous_score)
    # Créer ou mettre à jour l'analyse
    analysis = state.analysis || state.build_analysis
    analysis.update!(
      resume: parsed["resume"],
      score: [parsed["score"].to_i, previous_score].max # Ne jamais diminuer
    )

    # Mettre à jour le state avec les infos émotionnelles
    grief_stage = find_grief_stage_by_french(parsed["grief_stage"])

    state_attrs = { grief_stage: grief_stage }
    state_attrs[:pain_level] = parsed["pain_level"].to_i.clamp(0, 10) if parsed["pain_level"].present?
    state_attrs[:emotion_label] = parsed["emotion_label"] if parsed["emotion_label"].present?
    state_attrs[:main_sentiment] = parsed["main_sentiment"] if parsed["main_sentiment"].present?
    state_attrs[:trigger_source] = parsed["trigger_source"] if parsed["trigger_source"].present? && valid_trigger_source?(parsed["trigger_source"])
    state_attrs[:ex_contact_frequency] = parsed["ex_contact_frequency"] if parsed["ex_contact_frequency"].present?
    state_attrs[:considered_reunion] = parsed["considered_reunion"] unless parsed["considered_reunion"].nil?
    state_attrs[:ruminating_frequency] = parsed["ruminating_frequency"] if parsed["ruminating_frequency"].present?
    state_attrs[:sleep_quality] = parsed["sleep_quality"] if parsed["sleep_quality"].present?
    state_attrs[:support_level] = parsed["support_level"] if parsed["support_level"].present?
    state_attrs[:habits_changed] = parsed["habits_changed"] if parsed["habits_changed"].present?
    state_attrs[:drugs] = parsed["drugs"] if parsed["drugs"].present?

    # Mettre à jour le raw_input avec le dernier message utilisateur si pas déjà rempli
    if state.raw_input.blank?
      last_user_message = @chat.messages.where(role: 'user').last
      state_attrs[:raw_input] = last_user_message&.content
    end

    state.update!(state_attrs)

    # Mettre à jour l'archétype utilisateur si détecté
    if parsed["profil_relationnel"].present?
      archetype = Archetype.find_by(archetype_name: parsed["profil_relationnel"])
      current_user.update(archetype: archetype) if archetype
    end
  end

  def find_grief_stage_by_french(stage_key)
    stage_mapping = {
      'déni' => 'Déni',
      'deni' => 'Déni',
      'colère' => 'Colère',
      'colere' => 'Colère',
      'marchandage' => 'Marchandage',
      'dépression' => 'Dépression',
      'depression' => 'Dépression',
      'acceptation' => 'Acceptation'
    }
    stage_name = stage_mapping[stage_key&.downcase] || 'Déni'
    GriefStage.find_by(name: stage_name) || GriefStage.first
  end

  def valid_trigger_source?(source)
    %w[instagram facebook linkedin tiktok snapchat twitter mémoire message chanson lieu photo objet rêve autre].include?(source&.downcase)
  end

  def handle_emergency_response
    # Message d'urgence prédéfini
    emergency_message = "Je sens que tu traverses un moment vraiment difficile. " \
                        "Si tu as des pensées sombres, je t'encourage à appeler le 3114 " \
                        "(numéro national de prévention du suicide). " \
                        "Tu n'es pas seul, et il y a des gens formés pour t'écouter."
    @chat.messages.create!(role: "assistant", content: emergency_message)
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

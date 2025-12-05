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
    messages = [
      { role: 'system', content: initial_prompt(current_user.initial_quiz) },
      { role: 'user', content: user_content }
    ]

    uri = URI('https://api.openai.com/v1/chat/completions')
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{ENV['OPENAI_API_KEY']}"

    request.body = {
      model: 'gpt-4.1',
      messages: messages,
      max_tokens: 400,
      temperature: 0.7
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    result = JSON.parse(response.body)
    response_content = result.dig('choices', 0, 'message', 'content')

    @chat.messages.create!(role: "assistant", content: response_content)
  end

  # Prompt d'analyse déclenché à la fermeture
  def run_analysis_prompt
    last_state = @chat.states.last
    return unless last_state

    # Construire l'historique de conversation complet
    conversation_complete = @chat.messages.order(created_at: :asc).map do |msg|
      "#{msg.role == 'user' ? 'Utilisateur' : 'Haven'}: #{msg.content}"
    end.join("\n\n")

    ruby_llm_chat = RubyLLM.chat(model: 'gpt-4.1', temperature: 0.2)
    prompt = analysis_prompt(conversation_complete, current_user.initial_quiz)

    response = ruby_llm_chat.ask(prompt)

    begin
      parsed = JSON.parse(response.content)
      save_analysis_results(last_state, parsed)
    rescue JSON::ParserError
      Rails.logger.error("Erreur parsing analyse: #{response.content}")
    end
  end

  def save_analysis_results(state, parsed)
    # Créer ou mettre à jour l'analyse avec le nouveau format
    analysis = state.analysis || state.build_analysis
    analysis.update!(
      resume: parsed["resume_conversation"]
    )

    # Mapper l'étape de deuil vers grief_stage
    grief_stage = find_grief_stage_by_french(parsed["etape_deuil"])

    state_attrs = { grief_stage: grief_stage }

    # Mapper intensite_emotionnelle vers pain_level (1-10)
    if parsed["intensite_emotionnelle"].present?
      state_attrs[:pain_level] = parsed["intensite_emotionnelle"].to_i.clamp(0, 10)
    end

    # Mapper emotion_dominante vers emotion_label
    state_attrs[:emotion_label] = parsed["emotion_dominante"] if parsed["emotion_dominante"].present?

    # Construire main_sentiment à partir des données disponibles
    if parsed["themes_recurrents"].present? && parsed["themes_recurrents"].is_a?(Array)
      state_attrs[:main_sentiment] = parsed["themes_recurrents"].join(", ")
    end

    # Mapper ruminations (boolean) vers ruminating_frequency
    if parsed["ruminations"] == true
      state_attrs[:ruminating_frequency] = "souvent"
    elsif parsed["ruminations"] == false
      state_attrs[:ruminating_frequency] = "rarement"
    end

    # Mapper signes_isolement vers support_level
    if parsed["signes_isolement"] == true
      state_attrs[:support_level] = "isole"
    elsif parsed["signes_isolement"] == false
      state_attrs[:support_level] = "entoure"
    end

    # Mapper attachement_ex vers ex_contact_frequency (approximation)
    attachement_mapping = {
      "fort" => "contact_frequent",
      "modéré" => "contact_occasionnel",
      "faible" => "contact_rare",
      "ambivalent" => "contact_occasionnel"
    }
    if parsed["attachement_ex"].present? && attachement_mapping[parsed["attachement_ex"]]
      state_attrs[:ex_contact_frequency] = attachement_mapping[parsed["attachement_ex"]]
    end

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
      # Anciennes valeurs
      'déni' => 'Déni',
      'deni' => 'Déni',
      'colère' => 'Colère',
      'colere' => 'Colère',
      'marchandage' => 'Marchandage',
      'dépression' => 'Dépression',
      'depression' => 'Dépression',
      'acceptation' => 'Acceptation',
      # Nouvelles valeurs du prompt
      'choc' => 'Déni',
      'tristesse' => 'Dépression',
      'reconstruction' => 'Acceptation'
    }
    stage_name = stage_mapping[stage_key&.downcase] || 'Déni'
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

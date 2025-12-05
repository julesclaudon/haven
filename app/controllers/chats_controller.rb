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

    user_content = extract_message_content
    if user_content.present?
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

    response = HTTParty.post(
      'https://api.openai.com/v1/chat/completions',
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{ENV['OPENAI_API_KEY']}"
      },
      body: {
        model: 'gpt-4.1',
        messages: messages,
        max_tokens: 400,
        temperature: 0.7
      }.to_json
    )

    parsed_response = response.parsed_response
    response_content = parsed_response.dig('choices', 0, 'message', 'content')
    @chat.messages.create!(role: "assistant", content: response_content)
  end

  # Prompt d'analyse déclenché à la fermeture
  def run_analysis_prompt
    last_state = @chat.states.last
    return unless last_state

    # Construire l'historique de conversation complet
    messages_count = @chat.messages.count
    conversation_complete = @chat.messages.order(created_at: :asc).map do |msg|
      "#{msg.role == 'user' ? 'Utilisateur' : 'Haven'}: #{msg.content}"
    end.join("\n\n")

    # DEBUG: Log de la conversation envoyée
    Rails.logger.info("=" * 50)
    Rails.logger.info("[ANALYSIS DEBUG] Chat ID: #{@chat.id}")
    Rails.logger.info("[ANALYSIS DEBUG] Messages count: #{messages_count}")
    Rails.logger.info("[ANALYSIS DEBUG] Conversation envoyée:")
    Rails.logger.info(conversation_complete.truncate(2000))
    Rails.logger.info("=" * 50)

    ruby_llm_chat = RubyLLM.chat(model: 'gpt-4.1')
    prompt = analysis_prompt(conversation_complete, current_user.initial_quiz)

    response = ruby_llm_chat.ask(prompt)

    # DEBUG: Log de la réponse brute
    Rails.logger.info("[ANALYSIS DEBUG] Réponse brute de l'IA:")
    Rails.logger.info(response.content)
    Rails.logger.info("=" * 50)

    begin
      # Nettoyer le contenu de la réponse (retirer les éventuels ```json et ```)
      json_content = response.content.strip
      json_content = json_content.gsub(/\A```json\s*/, '').gsub(/\A```\s*/, '').gsub(/\s*```\z/, '')

      Rails.logger.info("[ANALYSIS DEBUG] Contenu JSON nettoyé:")
      Rails.logger.info(json_content)

      parsed = JSON.parse(json_content)
      # DEBUG: Log du JSON parsé
      Rails.logger.info("[ANALYSIS DEBUG] JSON parsé:")
      Rails.logger.info(parsed.inspect)
      Rails.logger.info("=" * 50)
      save_analysis_results(last_state, parsed)
    rescue JSON::ParserError => e
      Rails.logger.error("[ANALYSIS ERROR] Erreur parsing JSON: #{e.message}")
      Rails.logger.error("[ANALYSIS ERROR] Contenu reçu: #{response.content}")
    end
  end

  def save_analysis_results(state, parsed)
    Rails.logger.info("[ANALYSIS DEBUG] Début save_analysis_results pour state #{state.id}")
    Rails.logger.info("[ANALYSIS DEBUG] JSON reçu: #{parsed.inspect}")

    # Créer ou mettre à jour l'analyse avec le nouveau format
    analysis = state.analysis || state.build_analysis
    analysis.update!(
      resume: parsed["resume_conversation"]
    )
    Rails.logger.info("[ANALYSIS DEBUG] Résumé sauvegardé: #{parsed['resume_conversation']&.truncate(100)}")

    # Mapper l'étape de deuil vers grief_stage
    grief_stage = find_grief_stage_by_french(parsed["etape_deuil"])
    Rails.logger.info("[ANALYSIS DEBUG] etape_deuil reçue: #{parsed['etape_deuil']} -> grief_stage: #{grief_stage&.name}")

    state_attrs = { grief_stage: grief_stage }

    # Mapper intensite_emotionnelle vers pain_level (1-10)
    if parsed["intensite_emotionnelle"].present?
      state_attrs[:pain_level] = parsed["intensite_emotionnelle"].to_i.clamp(0, 10)
      Rails.logger.info("[ANALYSIS DEBUG] intensite_emotionnelle: #{parsed['intensite_emotionnelle']} -> pain_level: #{state_attrs[:pain_level]}")
    end

    # Mapper emotion_dominante vers emotion_label
    if parsed["emotion_dominante"].present?
      state_attrs[:emotion_label] = parsed["emotion_dominante"]
      Rails.logger.info("[ANALYSIS DEBUG] emotion_dominante: #{parsed['emotion_dominante']}")
    end

    # Construire main_sentiment à partir des themes_recurrents
    if parsed["themes_recurrents"].present? && parsed["themes_recurrents"].is_a?(Array)
      state_attrs[:main_sentiment] = parsed["themes_recurrents"].join(", ")
      Rails.logger.info("[ANALYSIS DEBUG] themes_recurrents: #{parsed['themes_recurrents']} -> main_sentiment: #{state_attrs[:main_sentiment]}")
    end

    # Mapper ruminations (boolean) vers ruminating_frequency
    if parsed["ruminations"] == true
      state_attrs[:ruminating_frequency] = "souvent"
    elsif parsed["ruminations"] == false
      state_attrs[:ruminating_frequency] = "rarement"
    end
    Rails.logger.info("[ANALYSIS DEBUG] ruminations: #{parsed['ruminations']} -> ruminating_frequency: #{state_attrs[:ruminating_frequency]}")

    # Mapper signes_isolement vers support_level (si pas déjà défini par le JSON)
    if parsed["support_level"].present?
      state_attrs[:support_level] = parsed["support_level"]
      Rails.logger.info("[ANALYSIS DEBUG] support_level direct: #{parsed['support_level']}")
    elsif parsed["signes_isolement"] == true
      state_attrs[:support_level] = "isole"
      Rails.logger.info("[ANALYSIS DEBUG] signes_isolement: true -> support_level: isole")
    elsif parsed["signes_isolement"] == false
      state_attrs[:support_level] = "entoure"
      Rails.logger.info("[ANALYSIS DEBUG] signes_isolement: false -> support_level: entoure")
    end

    # Profil relationnel
    if parsed["profil_relationnel"].present?
      state_attrs[:profil_relationnel] = parsed["profil_relationnel"]
      Rails.logger.info("[ANALYSIS DEBUG] profil_relationnel: #{parsed['profil_relationnel']}")
    end

    # Nouveaux champs directs du JSON
    # Valider trigger_source contre les valeurs autorisées du modèle
    valid_triggers = %w[instagram facebook linkedin tiktok snapchat twitter mémoire message chanson lieu photo objet rêve autre]
    if parsed["trigger_source"].present? && valid_triggers.include?(parsed["trigger_source"])
      state_attrs[:trigger_source] = parsed["trigger_source"]
      Rails.logger.info("[ANALYSIS DEBUG] trigger_source: #{parsed['trigger_source']}")
    elsif parsed["trigger_source"].present?
      Rails.logger.warn("[ANALYSIS DEBUG] trigger_source ignoré (non valide): #{parsed['trigger_source']}")
    end

    if parsed["ex_contact_frequency"].present?
      state_attrs[:ex_contact_frequency] = parsed["ex_contact_frequency"]
      Rails.logger.info("[ANALYSIS DEBUG] ex_contact_frequency: #{parsed['ex_contact_frequency']}")
    end

    unless parsed["considered_reunion"].nil?
      state_attrs[:considered_reunion] = parsed["considered_reunion"]
      Rails.logger.info("[ANALYSIS DEBUG] considered_reunion: #{parsed['considered_reunion']}")
    end

    if parsed["sleep_quality"].present?
      state_attrs[:sleep_quality] = parsed["sleep_quality"]
      Rails.logger.info("[ANALYSIS DEBUG] sleep_quality: #{parsed['sleep_quality']}")
    end

    if parsed["habits_changed"].present?
      state_attrs[:habits_changed] = parsed["habits_changed"]
      Rails.logger.info("[ANALYSIS DEBUG] habits_changed: #{parsed['habits_changed']}")
    end

    # Mettre à jour le raw_input avec le dernier message utilisateur si pas déjà rempli
    if state.raw_input.blank?
      last_user_message = @chat.messages.where(role: 'user').last
      state_attrs[:raw_input] = last_user_message&.content
      Rails.logger.info("[ANALYSIS DEBUG] raw_input mis à jour avec dernier message utilisateur")
    end

    Rails.logger.info("[ANALYSIS DEBUG] Attributs finaux à sauvegarder: #{state_attrs.inspect}")

    state.update!(state_attrs)
    Rails.logger.info("[ANALYSIS DEBUG] State #{state.id} mis à jour avec succès")

    # Mettre à jour l'archétype final si les conditions sont remplies
    current_user.update_final_archetype!
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

  def extract_message_content
    # Gérer les params classiques (form submission)
    if params[:message].is_a?(ActionController::Parameters) || params[:message].is_a?(Hash)
      params[:message][:content]
    # Gérer le cas où params[:message] est nil mais content est à la racine
    elsif params[:content].present?
      params[:content]
    else
      nil
    end
  end
end

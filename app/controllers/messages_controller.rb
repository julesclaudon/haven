class MessagesController < ApplicationController
  include HavenPromptsHelper
  include ActionController::Live

  before_action :authenticate_user!
  before_action :set_chat

  def create
    return redirect_to @chat unless valid_message_params?
    return redirect_to @chat if @chat.closed?

    user_content = params[:message][:content]

    # Créer le message utilisateur
    @chat.messages.create!(role: 'user', content: user_content)

    # Appeler l'IA avec le mini-prompt (non-streaming pour fallback)
    process_ai_response(user_content)

    redirect_to @chat
  end

  # Action SSE pour le streaming
  def stream
    return render json: { error: 'Invalid params' }, status: :bad_request unless valid_message_params?
    return render json: { error: 'Chat closed' }, status: :forbidden if @chat.closed?

    user_content = params[:message][:content]

    # Créer le message utilisateur
    @chat.messages.create!(role: 'user', content: user_content)

    # Configurer les headers SSE
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Connection'] = 'keep-alive'
    response.headers['X-Accel-Buffering'] = 'no'

    full_response = ""

    begin
      stream_ai_response(user_content) do |chunk|
        full_response += chunk
        response.stream.write("data: #{chunk.to_json}\n\n")
      end

      # Envoyer un signal de fin
      response.stream.write("data: [DONE]\n\n")

      # Sauvegarder le message complet
      @chat.messages.create!(role: "assistant", content: full_response)
    rescue IOError => e
      Rails.logger.error("SSE stream error: #{e.message}")
    ensure
      response.stream.close
    end
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:chat_id])
  end

  def valid_message_params?
    params[:message].present? && params[:message][:content].present?
  end

  def process_ai_response(user_content)
    ruby_llm_chat = RubyLLM.chat(temperature: 0.75)
    build_conversation_history(ruby_llm_chat)

    response = ruby_llm_chat.with_instructions(mini_prompt).ask(user_content)
    response_content = response.content

    @chat.messages.create!(role: "assistant", content: response_content)
  end

  # Streaming via API OpenAI directement
  def stream_ai_response(user_content)
    messages = build_openai_messages(user_content)

    uri = URI('https://api.openai.com/v1/chat/completions')
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{ENV['OPENAI_API_KEY']}"

    request.body = {
      model: 'gpt-4.1',
      messages: messages,
      max_tokens: 400,
      temperature: 0.75,
      stream: true
    }.to_json

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request) do |response|
        response.read_body do |chunk|
          chunk.split("\n").each do |line|
            next if line.strip.empty?
            next unless line.start_with?('data: ')

            data = line[6..]
            next if data == '[DONE]'

            begin
              json = JSON.parse(data)
              content = json.dig('choices', 0, 'delta', 'content')
              yield content if content
            rescue JSON::ParserError
              next
            end
          end
        end
      end
    end
  end

  def build_openai_messages(user_content)
    messages = [{ role: 'system', content: mini_prompt }]

    # Limiter à 15 derniers messages pour optimiser les tokens
    @chat.messages.order(created_at: :desc).limit(15).reverse.each do |message|
      messages << { role: message.role, content: message.content }
    end

    messages << { role: 'user', content: user_content }
    messages
  end

  def build_conversation_history(ruby_llm_chat)
    # Limiter à 15 derniers messages
    @chat.messages.order(created_at: :desc).limit(15).reverse.each do |message|
      ruby_llm_chat.add_message(role: message.role, content: message.content)
    end
  end
end

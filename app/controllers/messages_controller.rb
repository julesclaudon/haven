class MessagesController < ApplicationController
  include HavenPromptsHelper

  before_action :authenticate_user!
  before_action :set_chat

  def create
    return redirect_to @chat unless valid_message_params?
    return redirect_to @chat if @chat.closed?

    user_content = params[:message][:content]

    # Créer le message utilisateur
    @chat.messages.create!(role: 'user', content: user_content)

    # Appeler l'IA avec le mini-prompt
    process_ai_response(user_content)

    redirect_to @chat
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:chat_id])
  end

  def valid_message_params?
    params[:message].present? && params[:message][:content].present?
  end

  def process_ai_response(user_content)
    ruby_llm_chat = RubyLLM.chat
    build_conversation_history(ruby_llm_chat)

    response = ruby_llm_chat.with_instructions(mini_prompt).ask(user_content)
    response_content = response.content

    # Gestion de l'urgence : sortie vide ou [URGENCE]
    if response_content.blank? || response_content.include?("[URGENCE]")
      handle_emergency_response
      return
    end

    @chat.messages.create!(role: "assistant", content: response_content)
  end

  def build_conversation_history(ruby_llm_chat)
    @chat.messages.order(created_at: :asc).each do |message|
      ruby_llm_chat.add_message(role: message.role, content: message.content)
    end
  end

  def handle_emergency_response
    emergency_message = "Je sens que tu traverses un moment vraiment difficile. " \
                        "Si tu as des pensées sombres, je t'encourage à appeler le 3114 " \
                        "(numéro national de prévention du suicide). " \
                        "Tu n'es pas seul, et il y a des gens formés pour t'écouter."
    @chat.messages.create!(role: "assistant", content: emergency_message)
  end
end

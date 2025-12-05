class GenerateChatTitleJob < ApplicationJob
  include HavenPromptsHelper

  queue_as :default

  def perform(chat_id)
    chat = Chat.find_by(id: chat_id)
    return unless chat

    conversation_history = chat.messages.order(created_at: :asc).map do |msg|
      "#{msg.role == 'user' ? 'Utilisateur' : 'Haven'}: #{msg.content}"
    end.join("\n\n")

    return if conversation_history.blank?

    ruby_llm_chat = RubyLLM.chat
    response = ruby_llm_chat.with_instructions(title_generation_prompt).ask(conversation_history)

    new_title = response.content.strip.gsub(/^["']|["']$/, '').truncate(100)

    chat.update_title_after_close(new_title)
  rescue StandardError => e
    Rails.logger.error("Erreur génération titre chat ##{chat_id}: #{e.message}")
  end
end

class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat

  def create
    @message = @chat.messages.build(message_params)
    @message.role = "user"

    if @message.save
      # TODO: Appeler l'IA pour générer une réponse
      redirect_to chat_path(@chat)
    else
      redirect_to chat_path(@chat), alert: "Erreur lors de l'envoi du message"
    end
  end

  private

  def set_chat
    @chat = Chat.joins(:state).where(states: { user_id: current_user.id }).find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end

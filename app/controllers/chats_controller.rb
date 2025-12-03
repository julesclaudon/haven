class ChatsController < ApplicationController
  before_action :authenticate_user!

  def index
    @chats = current_user.chats
  end

  def show
    @chat = current_user.chats.find(params[:id])
    @messages = @chat.messages
  end

  def create
    @chat = current_user.chats.create
    redirect_to @chat
  end
end

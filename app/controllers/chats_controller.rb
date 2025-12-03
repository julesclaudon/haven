class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_initial_quiz

  def index
    @chats = Chat.joins(:state).includes(:state).where(states: { user_id: current_user.id }).order(created_at: :desc)
  end

  def show
    @chat = Chat.joins(:state).where(states: { user_id: current_user.id }).find(params[:id])
    @messages = @chat.messages.order(:created_at)
  end

  def create
    @chat = Chat.create!(status: "active")
    redirect_to @chat
  end
end

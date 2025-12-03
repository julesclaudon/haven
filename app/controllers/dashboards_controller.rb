class DashboardsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_initial_quiz

  def show
    @initial_quiz = current_user.initial_quiz
    @grief_stages = GriefStage.all.order(:id)
    @states = current_user.states.includes(:grief_stage, :analysis).order(created_at: :desc)
    @latest_state = @states.first
    @latest_analysis = @latest_state&.analysis
    @current_score = @latest_analysis&.score || 0
  end
end

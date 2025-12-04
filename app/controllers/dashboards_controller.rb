class DashboardsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_initial_quiz

  def show
    @initial_quiz = current_user.initial_quiz
    @grief_stages = GriefStage.all.order(:id)
    @states = current_user.states.includes(:grief_stage, :analysis).order(created_at: :desc)

    # Prendre le dernier state qui a une analyse (pas forcément le plus récent)
    @latest_state_with_analysis = @states.joins(:analysis).first
    @latest_analysis = @latest_state_with_analysis&.analysis
    @current_score = @latest_analysis&.score || 0

    # Pour la card du milieu : dernier state avec analyse
    @latest_state = @latest_state_with_analysis

    # Days since breakup
    @days_since_breakup = if @initial_quiz&.relation_end_date
                            (Date.current - @initial_quiz.relation_end_date.to_date).to_i
                          else
                            0
                          end

    # Total chats count
    @total_chats = current_user.chats.count
  end
end

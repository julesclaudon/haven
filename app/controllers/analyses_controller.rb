class AnalysesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_initial_quiz

  def index
    @archetype = current_user.archetype
    @analyses = Analysis.joins(state: :user).where(users: { id: current_user.id }).order(created_at: :desc)
    @latest_analysis = @analyses.first

    # Calcul des 5 émotions prédominantes sur les 20 derniers states
    recent_state_ids = current_user.states.order(created_at: :desc).limit(20).pluck(:id)
    emotion_counts = State.where(id: recent_state_ids)
                          .where.not(emotion_label: [nil, ""])
                          .group(:emotion_label)
                          .count

    total = emotion_counts.values.sum.to_f
    @top_emotions = if total > 0
      emotion_counts
        .transform_values { |count| ((count / total) * 100).round }
        .sort_by { |_, v| -v }
        .first(5)
        .to_h
    else
      {}
    end
  end

  def show
    @analysis = Analysis.joins(state: :user).where(users: { id: current_user.id }).find(params[:id])
  end
end

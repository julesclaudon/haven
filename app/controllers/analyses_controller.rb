class AnalysesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_initial_quiz

  def index
    @archetype = current_user.archetype
    @analyses = Analysis.joins(state: :user).where(users: { id: current_user.id }).order(created_at: :desc)
    @latest_analysis = @analyses.first
    @initial_quiz = current_user.initial_quiz
    @all_states = current_user.states.order(created_at: :asc)

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

    # === INSIGHTS DATA ===

    # 1. Évolution de la douleur
    @pain_evolution = @all_states.where.not(pain_level: nil).pluck(:created_at, :pain_level)
    @first_pain = @pain_evolution.first&.last
    @last_pain = @pain_evolution.last&.last
    @pain_trend = if @first_pain && @last_pain && @pain_evolution.size > 1
                    @last_pain - @first_pain
                  else
                    nil
                  end

    # 2. Top déclencheurs
    @top_triggers = current_user.states
                      .where.not(trigger_source: [nil, ""])
                      .group(:trigger_source)
                      .count
                      .sort_by { |_, v| -v }
                      .first(3)
                      .to_h

    # 3. Moments difficiles (time_of_day)
    @time_of_day_stats = current_user.states
                           .where.not(time_of_day: [nil, ""])
                           .group(:time_of_day)
                           .count
    @worst_time = @time_of_day_stats.max_by { |_, v| v }&.first

    # 4. Évolution du score
    @score_evolution = @analyses.reorder(created_at: :asc).pluck(:created_at, :score)
    @first_score = @score_evolution.first&.last
    @last_score = @score_evolution.last&.last
    @score_trend = if @first_score && @last_score && @score_evolution.size > 1
                     @last_score - @first_score
                   else
                     nil
                   end

    # 5. Contact avec l'ex
    @ex_contact_stats = current_user.states
                          .where.not(ex_contact_frequency: [nil, ""])
                          .order(created_at: :asc)
                          .pluck(:ex_contact_frequency)
    @first_contact = @ex_contact_stats.first
    @last_contact = @ex_contact_stats.last

    # 6. Réconciliation envisagée
    reunion_stats = current_user.states.where.not(considered_reunion: nil)
    @reunion_yes = reunion_stats.where(considered_reunion: true).count
    @reunion_no = reunion_stats.where(considered_reunion: false).count
    @reunion_total = @reunion_yes + @reunion_no
    @reunion_percentage = @reunion_total > 0 ? ((@reunion_no.to_f / @reunion_total) * 100).round : nil

    # 7. Contexte relation
    @relation_duration = @initial_quiz&.relation_duration # en mois
    @days_since_breakup = if @initial_quiz&.relation_end_date
                            (Date.current - @initial_quiz.relation_end_date.to_date).to_i
                          else
                            nil
                          end
  end

  def show
    @analysis = Analysis.joins(state: :user).where(users: { id: current_user.id }).find(params[:id])
  end
end

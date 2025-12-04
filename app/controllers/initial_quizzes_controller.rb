class InitialQuizzesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_initial_quiz, only: [:show, :edit, :update]

  def new
    if current_user.initial_quiz
      redirect_to current_user.initial_quiz, notice: "Tu as déjà rempli le questionnaire."
    else
      @initial_quiz = InitialQuiz.new
    end
  end

  def create
    @initial_quiz = InitialQuiz.new(initial_quiz_params)
    @initial_quiz.user = current_user

    if @initial_quiz.save
      redirect_to dashboard_path, notice: "Bienvenue sur Haven ! Ton profil a été créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @initial_quiz.update(initial_quiz_params)
      redirect_to @initial_quiz, notice: "Quiz initial mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_initial_quiz
    @initial_quiz = current_user.initial_quiz
  end

  def initial_quiz_params
    params.require(:initial_quiz).permit(
      :age,
      :relation_end_date,
      :relation_duration,
      :pain_level,
      :breakup_type,
      :breakup_initiator,
      :emotion_label,
      :main_sentiment,
      :ex_contact_frequency,
      :considered_reunion,
      :ruminating_frequency,
      :sleep_quality,
      :habits_changed,
      :support_level
    )
  end
end

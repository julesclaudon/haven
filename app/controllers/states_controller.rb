class StatesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_initial_quiz
  before_action :set_state, only: [:show]

  def index
    @states = current_user.states.includes(:grief_stage, :chat).order(created_at: :desc)
  end

  def new
    @state = State.new
  end

  def create
    @state = State.new(state_params)
    @state.user = current_user

    if @state.save
      redirect_to @state, notice: "État enregistré avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @after_close = params[:after_close].present?
    render layout: "iframe" if params[:iframe]
  end

  private

  def set_state
    @state = current_user.states.find(params[:id])
  end

  def state_params
    params.require(:state).permit(
      :chat_id,
      :grief_stage_id,
      :pain_level,
      :raw_input,
      :trigger_source,
      :time_of_day,
      :drugs,
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

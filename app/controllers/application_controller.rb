class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end

  def require_initial_quiz
    return unless user_signed_in?
    return if controller_name == "initial_quizzes"
    return if devise_controller?

    unless current_user.initial_quiz
      redirect_to new_initial_quiz_path, alert: "Tu dois d'abord remplir le questionnaire initial."
    end
  end
end

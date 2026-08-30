# frozen_string_literal: true

class SessionsController < ApplicationController
  RATE_LIMIT_ALERT = "Demasiados intentos. Esperá unos minutos."
  INVALID_CREDENTIALS_ALERT = "Email o contraseña incorrectos."

  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to sign_in_url, alert: RATE_LIMIT_ALERT }

  layout "diario"

  def new
  end

  def create
    if (user = User.authenticate_by(params.permit(:email_address, :password)))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to sign_in_path, alert: INVALID_CREDENTIALS_ALERT
    end
  end

  def destroy
    terminate_session
    redirect_to sign_in_path
  end
end

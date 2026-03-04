# frozen_string_literal: true

class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to sign_in_url, alert: "Demasiados intentos. Esperá unos minutos." } # rubocop:disable Rails/I18nLocaleTexts

  layout "diario"

  def new
  end

  def create
    if (user = User.authenticate_by(params.permit(:email_address, :password)))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to sign_in_path, alert: "Email o contraseña incorrectos." # rubocop:disable Rails/I18nLocaleTexts
    end
  end

  def destroy
    terminate_session
    redirect_to sign_in_path
  end
end

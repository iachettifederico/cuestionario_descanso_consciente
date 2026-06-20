# frozen_string_literal: true

class RegistrationsController < ApplicationController
  WELCOME_NOTICE = "¡Bienvenida! Tu diario de 15 días está listo para comenzar."

  allow_unauthenticated_access only: %i[new create]
  layout "diario"

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for(@user)
      redirect_to diary_path, notice: WELCOME_NOTICE
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: %i[name email_address password password_confirmation])
  end
end

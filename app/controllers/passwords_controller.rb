# frozen_string_literal: true

class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to sign_in_path, notice: "Te enviamos las instrucciones si existe una cuenta con ese correo."
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      redirect_to sign_in_path, notice: "La contraseña se actualizó correctamente."
    else
      redirect_to edit_password_path(params[:token]), alert: "Las contraseñas no coinciden."
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_password_reset_token!(params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    redirect_to new_password_path, alert: "El enlace para restablecer la contraseña no es válido o expiró."
  end
end

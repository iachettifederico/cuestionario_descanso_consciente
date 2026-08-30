# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Passwords", type: :request do
  let!(:user) do
    User.create!(
      name: "Test User",
      email_address: "user@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  it "shows the password reset form" do
    get new_password_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Restablecer contraseña")
  end

  it "redirects after requesting reset instructions" do
    post passwords_path, params: { email_address: user.email_address }

    expect(response).to redirect_to(sign_in_path)
  end

  it "redirects after requesting reset instructions for an unknown email" do
    post passwords_path, params: { email_address: "missing@example.com" }

    expect(response).to redirect_to(sign_in_path)
  end

  it "shows the password reset edit form" do
    token = user.password_reset_token

    get edit_password_path(token)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Elegí una nueva contraseña")
  end

  it "updates the password with a valid token" do
    token = user.password_reset_token

    put password_path(token), params: {
      password: "new-password",
      password_confirmation: "new-password"
    }

    expect(response).to redirect_to(sign_in_path)
    expect(user.reload.authenticate("new-password")).to be_present
  end

  it "rejects mismatched password confirmation" do
    token = user.password_reset_token

    put password_path(token), params: {
      password: "new-password",
      password_confirmation: "different-password"
    }

    expect(response).to redirect_to(edit_password_path(token))
  end

  it "redirects invalid password reset tokens" do
    get edit_password_path("invalid-token")

    expect(response).to redirect_to(new_password_path)
  end

  it "redirects invalid password reset updates" do
    put password_path("invalid-token"), params: {
      password: "new-password",
      password_confirmation: "new-password"
    }

    expect(response).to redirect_to(new_password_path)
  end
end

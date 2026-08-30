# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) do
    User.create!(
      name: "Test User",
      email_address: "user@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  it "shows the sign in page" do
    get sign_in_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ingresar")
  end

  it "signs in with valid credentials" do
    post sign_in_path, params: { email_address: user.email_address, password: "password" }

    expect(response).to redirect_to(root_path)
  end

  it "returns to the originally requested page after sign in" do
    get diary_day_path(3)

    expect(response).to redirect_to(sign_in_path)

    post sign_in_path, params: { email_address: user.email_address, password: "password" }

    expect(response).to redirect_to(diary_day_path(3))
  end

  it "rejects invalid credentials" do
    post sign_in_path, params: { email_address: user.email_address, password: "bad-password" }

    expect(response).to redirect_to(sign_in_path)
    follow_redirect!
    expect(response.body).to include("Email o contraseña incorrectos.")
  end

  it "signs out" do
    post sign_in_path, params: { email_address: user.email_address, password: "password" }
    delete sign_out_path

    expect(response).to redirect_to(sign_in_path)
  end

  it "signs out safely even without a current session" do
    delete sign_out_path

    expect(response).to redirect_to(sign_in_path)
  end

  it "clears stale session cookies and redirects to sign in" do
    post sign_in_path, params: { email_address: user.email_address, password: "password" }
    session_id = cookies[:session_id]

    Session.delete_all

    get diary_path

    expect(response).to redirect_to(sign_in_path)
    expect(cookies[:session_id]).to be_blank
    expect(session_id).to be_present
  end
end

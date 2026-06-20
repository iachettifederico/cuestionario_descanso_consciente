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

  it "rejects invalid credentials" do
    post sign_in_path, params: { email_address: user.email_address, password: "bad-password" }

    expect(response).to redirect_to(sign_in_path)
  end

  it "signs out" do
    post sign_in_path, params: { email_address: user.email_address, password: "password" }
    delete sign_out_path

    expect(response).to redirect_to(sign_in_path)
  end
end

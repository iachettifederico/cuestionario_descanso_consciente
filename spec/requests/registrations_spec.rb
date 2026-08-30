# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Registrations", type: :request do
  it "shows the sign up page" do
    get sign_up_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Crear mi cuenta")
  end

  it "creates a user and redirects to the diary" do
    post sign_up_path, params: {
      user: {
        name: "New User",
        email_address: "new@example.com",
        password: "password",
        password_confirmation: "password"
      }
    }

    expect(response).to redirect_to(diary_path)
    expect(User.find_by(email_address: "new@example.com")).to be_present
  end

  it "renders the form again for invalid input" do
    post sign_up_path, params: {
      user: {
        name: "",
        email_address: "",
        password: "password",
        password_confirmation: "password"
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
  end
end

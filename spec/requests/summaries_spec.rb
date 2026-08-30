# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Summaries", type: :request do
  let(:user) do
    User.create!(
      name: "Test User",
      email_address: "user@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  def sign_in
    post sign_in_path, params: { email_address: user.email_address, password: "password" }
  end

  it "redirects anonymous users to sign in" do
    get summary_path

    expect(response).to redirect_to(sign_in_path)
  end

  it "shows the summary for a signed-in user" do
    user.diary_entries.create!(day_number: 1, saved: true, horas_dormidas: 7.5, ratings: { "fisico" => 4 }.to_json)
    user.diary_entries.create!(day_number: 15, saved: true, micropausa: "Respirar", pausa_estrella: "Respirar")

    sign_in
    get summary_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Observación del")
    expect(response.body).to include("Mi micro-pausa estrella")
  end

  it "shows the empty state when there is no summary data" do
    sign_in
    get summary_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Completá algunos días para ver tus patrones aquí.")
  end

  it "falls back to the latest micropausa when day 15 has no star pause" do
    user.diary_entries.create!(day_number: 10, saved: true, micropausa: "Una pausa reciente")
    user.diary_entries.create!(day_number: 15, saved: true)

    sign_in
    get summary_path

    expect(response.body).to include("Una pausa reciente")
  end
end

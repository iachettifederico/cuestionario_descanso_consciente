# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Subdomain routes", type: :request do
  it "routes the cuestionario subdomain root to the questionnaire" do
    host! "cuestionario.example.com"

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("¿Qué vas a descubrir con este cuestionario?")
  end

  it "routes the diario subdomain root to the diary" do
    host! "diario.example.com"

    get "/"

    expect(response).to redirect_to(sign_in_path)
  end

  it "keeps the main domain on the home page" do
    host! "example.com"

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("http://cuestionario.example.com/")
    expect(response.body).to include("http://diario.example.com/")
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Path routes", type: :request do
  it "routes the questionnaire path to the questionnaire" do
    get cuestionario_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("¿Qué vas a descubrir con este cuestionario?")
  end

  it "routes the diary path to the diary" do
    get diary_path

    expect(response).to redirect_to(sign_in_path)
  end

  it "links to the questionnaire and diary paths from the home page" do
    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("href=\"/cuestionario\"")
    expect(response.body).to include("href=\"/diario\"")
  end
end

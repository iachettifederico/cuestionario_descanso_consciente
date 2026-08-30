# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cuestionario", type: :request do
  let!(:first_category) do
    Category.create!(name: "Cansancio Físico", identifier: "fisico", description: "Descanso físico", position: 0)
  end
  let!(:second_category) do
    Category.create!(name: "Cansancio Mental", identifier: "mental", description: "Descanso mental", position: 1)
  end
  let!(:first_question) do
    first_category.questions.create!(text: "¿Te cuesta sostener energía física?", position: 0)
  end
  let!(:second_question) do
    second_category.questions.create!(text: "¿Te cuesta concentrarte?", position: 0)
  end

  it "shows the welcome page" do
    get cuestionario_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Descanso Consciente")
  end

  it "keeps the user on the same category when answers are missing" do
    post cuestionario_category_path(first_category.identifier), params: { answers: { first_question.id.to_s => "" } }

    expect(response).to redirect_to(cuestionario_category_path(first_category.identifier))
  end

  it "keeps the user on the same category when only some answers are present" do
    post cuestionario_category_path(second_category.identifier), params: { answers: { second_question.id.to_s => "" } }

    expect(response).to redirect_to(cuestionario_category_path(second_category.identifier))
  end

  it "progresses through categories and shows results" do
    post cuestionario_category_path(first_category.identifier), params: { answers: { first_question.id.to_s => "3" } }

    expect(response).to redirect_to(cuestionario_category_path(second_category.identifier))

    post cuestionario_category_path(second_category.identifier), params: { answers: { second_question.id.to_s => "1" } }

    expect(response).to redirect_to("/cuestionario/formulario")

    get cuestionario_resultados_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Cansancio Físico")
  end
end

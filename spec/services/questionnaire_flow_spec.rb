# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionnaireFlow do
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

  let(:session) { {} }
  let(:params) { ActionController::Parameters.new(raw_params) }
  let(:raw_params) { {} }

  subject(:flow) { described_class.new(params: params, session: session) }

  it "returns the first category by default" do
    expect(flow.category).to eq(first_category)
    expect(flow.current_category_position).to eq(1)
    expect(flow.next_category).to eq(second_category)
  end

  it "finds the previous category when a category id is given" do
    params[:category_id] = second_category.identifier

    expect(flow.category).to eq(second_category)
    expect(flow.previous_category).to eq(first_category)
  end

  it "stores answers in the session" do
    params[:answers] = {
      first_question.id.to_s => "3",
      second_question.id.to_s => "1"
    }

    flow.store_answers!

    expect(session[:questionnaire_answers]).to eq(first_question.id.to_s => 3, second_question.id.to_s => 1)
  end

  it "checks whether all questions were answered" do
    params[:category_id] = first_category.identifier
    params[:answers] = { first_question.id.to_s => "3" }

    expect(flow.all_questions_answered?).to be(true)
  end

  it "calculates category scores and the predominant tiredness" do
    session[:questionnaire_answers] = {
      first_question.id.to_s => 3,
      second_question.id.to_s => 1
    }

    expect(flow.category_scores[first_category.id]).to eq(3)
    expect(flow.category_scores[second_category.id]).to eq(1)
    expect(flow.predominant_tiredness).to eq(first_category)
  end
end

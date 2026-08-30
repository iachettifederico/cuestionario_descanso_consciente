# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionnaireResultPresenter do
  let(:first_category) do
    Category.create!(name: "Físico", identifier: "fisico", description: "Descanso físico", position: 0)
  end
  let(:second_category) do
    Category.create!(name: "Mental", identifier: "mental", description: "Descanso mental", position: 1)
  end
  let(:third_category) do
    Category.create!(name: "Emocional", identifier: "emocional", description: "Descanso emocional", position: 2)
  end

  let(:categories) { [first_category, second_category, third_category] }
  let(:scores) { { first_category.id => 12, second_category.id => 8, third_category.id => 2 } }
  let(:presenter) { described_class.new(categories: categories, category_scores: scores, predominant_tiredness: first_category) }

  it "sums total responses" do
    expect(presenter.total_responses).to eq(22)
  end

  it "sorts categories by score descending" do
    expect(presenter.sorted_categories).to eq([first_category, second_category, third_category])
  end

  it "returns the score and percentage for a category" do
    expect(presenter.score_for(first_category)).to eq(12)
    expect(presenter.percentage_for(first_category)).to eq(67)
  end

  it "returns styling and recommendation for a high score" do
    expect(presenter.category_color_class(first_category)).to eq("border-coral hover:border-coral")
    expect(presenter.badge_color_class(first_category)).to eq("bg-coral text-white")
    expect(presenter.progress_bar_color(first_category)).to eq("progress-bar high")
    expect(presenter.recommendation_text(first_category)).to include("afectando seriamente")
  end

  it "returns styling and recommendation for a moderate score" do
    expect(presenter.category_color_class(second_category)).to eq("border-yellow hover:border-yellow-600")
    expect(presenter.badge_color_class(second_category)).to eq("bg-yellow-400 text-gray-800")
    expect(presenter.progress_bar_color(second_category)).to eq("progress-bar moderate")
    expect(presenter.recommendation_text(second_category)).to include("revisar y mejorar")
  end

  it "returns styling and recommendation for a low score" do
    expect(presenter.category_color_class(third_category)).to eq("border-green-light hover:border-green")
    expect(presenter.badge_color_class(third_category)).to eq("bg-green-light text-white")
    expect(presenter.progress_bar_color(third_category)).to eq("progress-bar good")
    expect(presenter.recommendation_text(third_category)).to include("manejando bien")
  end

  it "uses PDF border classes when requested" do
    expect(presenter.category_color_class(first_category, pdf: true)).to eq("border-coral")
  end
end

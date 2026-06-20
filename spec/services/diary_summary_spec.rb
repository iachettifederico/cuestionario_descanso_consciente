# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiarySummary do
  let(:user) do
    User.create!(
      name: "Test User",
      email_address: "user@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  subject(:summary) { described_class.new(user: user) }

  it "returns empty values when there is no diary data" do
    expect(summary.completed_days).to eq([])
    expect(summary.fatigue_averages).to eq({})
    expect(summary.sleep_average).to be_nil
    expect(summary.top_tipo).to be_nil
    expect(summary.pausa_estrella).to be_nil
    expect(summary.sorted_tipos).to eq(DiaryEntry::TIPO_LABELS.keys)
  end

  it "calculates fatigue averages and ignores malformed JSON" do
    user.diary_entries.create!(day_number: 1, saved: true, ratings: { "fisico" => 3, "mental" => 1 }.to_json)
    user.diary_entries.create!(day_number: 2, saved: true, ratings: { "fisico" => 5, "mental" => 0 }.to_json)
    user.diary_entries.create!(day_number: 3, saved: true, ratings: "not-json")

    expect(summary.fatigue_averages).to eq("fisico" => 4.0, "mental" => 1.0)
  end

  it "calculates the sleep average" do
    user.diary_entries.create!(day_number: 1, saved: true, horas_dormidas: 7.0)
    user.diary_entries.create!(day_number: 2, saved: true, horas_dormidas: 8.5)

    expect(summary.sleep_average).to eq(7.8)
  end

  it "returns the day 15 entry and top tipo" do
    user.diary_entries.create!(day_number: 1, saved: true, ratings: { "fisico" => 5 }.to_json)
    day15 = user.diary_entries.create!(day_number: 15, saved: true, pausa_estrella: "Respirar")

    expect(summary.day15_entry).to eq(day15)
    expect(summary.top_tipo).to eq("fisico")
    expect(summary.pausa_estrella).to eq("Respirar")
  end

  it "falls back to the latest micropausa when day 15 has no star pause" do
    user.diary_entries.create!(day_number: 2, saved: true, micropausa: "Primera micro pausa")
    user.diary_entries.create!(day_number: 10, saved: true, micropausa: "Última micro pausa")
    user.diary_entries.create!(day_number: 15, saved: true, micropausa: "")

    expect(summary.pausa_estrella).to eq("Última micro pausa")
  end

  it "sorts tipos by descending averages" do
    user.diary_entries.create!(day_number: 1, saved: true, ratings: { "fisico" => 1, "mental" => 2, "emocional" => 3 }.to_json)
    user.diary_entries.create!(day_number: 2, saved: true, ratings: { "fisico" => 3, "mental" => 5, "emocional" => 1 }.to_json)

    expect(summary.sorted_tipos.first).to eq("mental")
    expect(summary.sorted_tipos).to include("fisico", "emocional")
  end
end

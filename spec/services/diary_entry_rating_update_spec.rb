# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiaryEntryRatingUpdate do
  let(:user) do
    User.create!(
      name: "Test User",
      email_address: "user@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  let(:entry) { DiaryEntry.create!(user: user, day_number: 1) }

  it "returns ok when the rating is saved" do
    result = described_class.new(entry: entry, tipo: "fisico", valor: 4).call

    expect(result.success?).to be(true)
    expect(result.status).to eq(:ok)
    expect(result.payload).to eq({ ok: true })
    expect(entry.rating_for("fisico")).to eq(4)
  end

  it "returns invalid parameters for bad types or values" do
    result = described_class.new(entry: entry, tipo: "bogus", valor: 4).call

    expect(result.success?).to be(false)
    expect(result.status).to eq(:unprocessable_entity)
    expect(result.payload).to eq({ error: "Parámetros inválidos" })
  end

  it "returns unavailable type errors" do
    result = described_class.new(entry: entry, tipo: "mental", valor: 4).call

    expect(result.success?).to be(false)
    expect(result.status).to eq(:unprocessable_entity)
    expect(result.payload).to eq({ error: "Tipo no disponible para este día" })
  end

  it "returns failure when the update cannot be persisted" do
    allow(entry).to receive(:update_rating).and_return(false)

    result = described_class.new(entry: entry, tipo: "fisico", valor: 4).call

    expect(result.success?).to be(false)
    expect(result.status).to eq(:unprocessable_entity)
    expect(result.payload).to eq({ error: "No se pudo guardar" })
  end
end

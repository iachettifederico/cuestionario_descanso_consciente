# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiaryEntry, type: :model do
  let(:user) do
    User.create!(
      name: "Test User",
      email_address: "user@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  describe "validations" do
    it "requires a day between 1 and 15" do
      entry = described_class.new(user: user, day_number: 0)

      expect(entry).not_to be_valid
      expect(entry.errors[:day_number]).to include("is not included in the list")
    end

    it "enforces one entry per user and day" do
      described_class.create!(user: user, day_number: 1)
      duplicate = described_class.new(user: user, day_number: 1)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("has already been taken")
    end
  end

  describe "ratings" do
    let(:entry) { described_class.create!(user: user, day_number: 3) }

    it "returns an empty hash for invalid JSON" do
      entry.update_column(:ratings, "not-json")

      expect(entry.ratings_hash).to eq({})
    end

    it "reads and writes ratings" do
      expect(entry.update_rating("fisico", 4)).to be(true)

      expect(entry.rating_for("fisico")).to eq(4)
      expect(entry.ratings_hash).to eq("fisico" => 4)
    end

    it "rejects invalid rating types and values" do
      expect(entry.rating_update_error("not-a-type", 4)).to eq(:invalid_type)
      expect(entry.rating_update_error("fisico", 0)).to eq(:invalid_value)
    end

    it "rejects unavailable types for the day" do
      expect(entry.rating_update_error("emocional", 4)).to eq(:type_not_available)
    end
  end

  describe "day helpers" do
    it "exposes the types available for a day" do
      entry = described_class.new(user: user, day_number: 5)

      expect(entry.tipos_disponibles).to eq(%w[fisico mental emocional])
      expect(entry.tipo_nuevo).to eq("emocional")
      expect(entry.reflexion_day?).to be(false)
      expect(entry.micropausa_day?).to be(true)
      expect(entry.last_day?).to be(false)
    end

    it "marks the last day" do
      entry = described_class.new(user: user, day_number: 15)

      expect(entry.last_day?).to be(true)
      expect(entry.pausa_sugerida).to include(:icon, :text)
    end
  end

  describe "delegation to diary day config" do
    it "uses the shared config for type labels" do
      expect(DiaryDayConfig.type_labels).to include("fisico")
      expect(DiaryDayConfig.type_label("fisico")).to include(label: "Físico")
    end
  end
end

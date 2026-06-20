# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "requires a name" do
      user = described_class.new(
        email_address: "test@example.com",
        password: "password",
        password_confirmation: "password"
      )

      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it "normalizes the email address" do
      user = described_class.create!(
        name: "Test User",
        email_address: "  TEST@Example.com  ",
        password: "password",
        password_confirmation: "password"
      )

      expect(user.email_address).to eq("test@example.com")
    end

    it "rejects duplicate email addresses" do
      described_class.create!(
        name: "First User",
        email_address: "unique@example.com",
        password: "password",
        password_confirmation: "password"
      )

      duplicate = described_class.new(
        name: "Second User",
        email_address: "UNIQUE@example.com",
        password: "password",
        password_confirmation: "password"
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email_address]).to include("has already been taken")
    end
  end

  describe "diary helpers" do
    let(:user) do
      described_class.create!(
        name: "Test User",
        email_address: "user@example.com",
        password: "password",
        password_confirmation: "password"
      )
    end

    it "finds entries by day" do
      entry = user.diary_entries.create!(day_number: 3, saved: true)

      expect(user.entry_for(3)).to eq(entry)
    end

    it "counts completed days" do
      user.diary_entries.create!(day_number: 1, saved: true)
      user.diary_entries.create!(day_number: 2, saved: false)
      user.diary_entries.create!(day_number: 3, saved: true)

      expect(user.completed_days).to eq(2)
    end

    it "returns the next pending day" do
      user.diary_entries.create!(day_number: 1, saved: true)
      user.diary_entries.create!(day_number: 3, saved: true)

      expect(user.next_pending_day).to eq(2)
    end

    it "returns the last day when all days are complete" do
      (1..15).each do |day_number|
        user.diary_entries.create!(day_number: day_number, saved: true)
      end

      expect(user.next_pending_day).to eq(15)
    end

    it "calculates fatigue averages and ignores malformed JSON" do
      user.diary_entries.create!(day_number: 1, saved: true, ratings: { "fisico" => 3, "mental" => 1 }.to_json)
      user.diary_entries.create!(day_number: 2, saved: true, ratings: { "fisico" => 5 }.to_json)
      user.diary_entries.create!(day_number: 3, saved: true, ratings: "not-json")

      expect(user.fatigue_averages).to eq("fisico" => 4.0, "mental" => 1.0)
    end

    it "calculates the sleep average" do
      user.diary_entries.create!(day_number: 1, saved: true, horas_dormidas: 7.0)
      user.diary_entries.create!(day_number: 2, saved: true, horas_dormidas: 8.5)

      expect(user.sleep_average).to eq(7.8)
    end
  end
end

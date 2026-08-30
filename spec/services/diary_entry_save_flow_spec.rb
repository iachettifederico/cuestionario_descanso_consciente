# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiaryEntrySaveFlow do
  include Rails.application.routes.url_helpers

  let(:user) do
    User.create!(
      name: "Test User",
      email_address: "user@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  let(:day_number) { 1 }
  let(:entry) { DiaryEntry.create!(user: user, day_number: day_number) }

  describe "day save redirects" do
    let(:day_number) { 1 }

    it "redirects to the next day when save and continue is used" do
      result = described_class.new(entry: entry, day: 1, save_and_next: true).call(
        fecha: "2026-06-20",
        palabra: "cansancio"
      )

      expect(result.success?).to be(true)
      expect(result.redirect_path).to eq(diary_day_path(2))
      expect(result.notice).to eq("Día 1 guardado ✓")
      expect(entry.reload.saved).to be(true)
    end

    it "redirects to the same day when save and continue is not used" do
      result = described_class.new(entry: entry, day: 1, save_and_next: false).call(
        fecha: "2026-06-20",
        palabra: "cansancio"
      )

      expect(result.success?).to be(true)
      expect(result.redirect_path).to eq(diary_day_path(1))
    end
  end

  it "redirects day 15 to the summary" do
    day15_entry = DiaryEntry.create!(user: user, day_number: 15)

    result = described_class.new(entry: day15_entry, day: 15, save_and_next: true).call(
      fecha: "2026-06-20",
      palabra: "cierre"
    )

    expect(result.success?).to be(true)
    expect(result.redirect_path).to eq(summary_path)
    expect(result.notice).to eq("¡Completaste los 15 días! 🎉")
  end

  it "returns failure when the entry cannot be saved" do
    allow(entry).to receive(:update).and_return(false)

    result = described_class.new(entry: entry, day: 1, save_and_next: false).call({})

    expect(result.success?).to be(false)
    expect(result.redirect_path).to be_nil
    expect(result.notice).to be_nil
  end
end

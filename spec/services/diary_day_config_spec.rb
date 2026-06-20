# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiaryDayConfig do
  it "returns the expected types by day" do
    expect(described_class.types_for(1)).to eq(%w[fisico])
    expect(described_class.types_for(5)).to eq(%w[fisico mental emocional])
    expect(described_class.types_for(15)).to eq(%w[fisico mental emocional sensorial social creativo espiritual])
  end

  it "returns the expected type labels" do
    expect(described_class.type_label("fisico")).to include(label: "Físico", icon: "💪")
    expect(described_class.type_label(:mental)).to include(label: "Mental", icon: "🧠")
  end

  it "returns the expected pause suggestions" do
    expect(described_class.suggested_pause_for(1)).to include(:icon, :text)
    expect(described_class.suggested_pause_for(15)).to include(:icon, :text)
  end

  it "identifies reflection and micropause days" do
    expect(described_class.reflection_day?(2)).to be(true)
    expect(described_class.reflection_day?(3)).to be(false)
    expect(described_class.micropause_day?(1)).to be(true)
    expect(described_class.micropause_day?(2)).to be(false)
  end

  it "returns the new type and last day predicates" do
    expect(described_class.new_type_for(3)).to eq("mental")
    expect(described_class.new_type_for(4)).to be_nil
    expect(described_class.last_day?(15)).to be(true)
    expect(described_class.last_day?(14)).to be(false)
  end
end

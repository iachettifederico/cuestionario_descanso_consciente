# frozen_string_literal: true

class DiarySummary
  attr_reader :user

  def initialize(user:)
    @user = user
  end

  def completed_days
    @completed_days ||= diary_entries.where(saved: true).pluck(:day_number)
  end

  def fatigue_averages # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    @fatigue_averages ||= begin
      entries = diary_entries.where.not(ratings: [nil, "{}"])
      sums = Hash.new(0)
      counts = Hash.new(0)

      entries.each do |entry|
        ratings = parse_ratings(entry.ratings)
        ratings.each do |tipo, val|
          next unless val.to_i.positive?

          sums[tipo] += val.to_i
          counts[tipo] += 1
        end
      end

      sums.each_with_object({}) do |(tipo, sum), averages|
        averages[tipo] = (sum.to_f / counts[tipo]).round(1)
      end
    end
  end

  def sleep_average
    @sleep_average ||= begin
      entries = diary_entries.where.not(horas_dormidas: nil)
      entries.empty? ? nil : (entries.sum(:horas_dormidas) / entries.count).round(1)
    end
  end

  def day15_entry
    @day15_entry ||= user.entry_for(15)
  end

  def top_tipo
    @top_tipo ||= fatigue_averages.max_by { |_, value| value }&.first
  end

  def pausa_estrella
    @pausa_estrella ||= begin
      day15_entry&.pausa_estrella.presence ||
        diary_entries
          .where.not(micropausa: [nil, ""])
          .order(day_number: :desc)
          .first&.micropausa&.truncate(120)
    end
  end

  def sorted_tipos
    @sorted_tipos ||= DiaryDayConfig.type_labels.keys.sort_by { |tipo| -(fatigue_averages[tipo] || 0) }
  end

  private

  def diary_entries
    user.diary_entries
  end

  def parse_ratings(ratings_json)
    JSON.parse(ratings_json)
  rescue StandardError
    {}
  end
end

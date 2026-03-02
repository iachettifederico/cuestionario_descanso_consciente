# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  has_many :diary_entries, dependent: :destroy
  has_many :sessions, dependent: :destroy

  validates :email_address, presence:   true,
                            uniqueness: true,
                            format:     { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def entry_for(day)
    diary_entries.find_by(day_number: day)
  end

  def completed_days
    diary_entries.where(saved: true).count
  end

  def next_pending_day
    completed = diary_entries.where(saved: true).pluck(:day_number)
    (1..15).find { |d| completed.exclude?(d) } || 15
  end

  def fatigue_averages # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    entries = diary_entries.where.not(ratings: [nil, "{}"])
    sums = Hash.new(0)
    counts = Hash.new(0)

    entries.each do |entry|
      begin
        ratings = JSON.parse(entry.ratings)
      rescue JSON::ParserError
        ratings = {}
      end
      ratings.each do |tipo, val|
        next unless val.to_i.positive?

        sums[tipo] += val.to_i
        counts[tipo] += 1
      end
    end

    averages = {}
    sums.each do |tipo, sum|
      averages[tipo] = (sum.to_f / counts[tipo]).round(1)
    end
    averages
  end

  def sleep_average
    entries = diary_entries.where.not(horas_dormidas: nil)
    return nil if entries.empty?

    (entries.sum(:horas_dormidas) / entries.count).round(1)
  end
end

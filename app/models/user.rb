# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  generates_token_for :password_reset, expires_in: 15.minutes do
    password_digest.last(10)
  end
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

  def fatigue_averages
    DiarySummary.new(user: self).fatigue_averages
  end

  def sleep_average
    DiarySummary.new(user: self).sleep_average
  end
end

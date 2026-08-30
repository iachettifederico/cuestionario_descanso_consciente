# frozen_string_literal: true

class DiaryEntry < ApplicationRecord # rubocop:disable Metrics/ClassLength
  belongs_to :user

  validates :day_number, presence: true, inclusion: { in: 1..15 }
  validates :user_id, uniqueness: { scope: :day_number }

  def tipos_disponibles
    DiaryDayConfig.types_for(day_number)
  end

  def ratings_hash
    JSON.parse(ratings.presence || "{}")
  rescue StandardError
    {}
  end

  def rating_for(tipo)
    ratings_hash[tipo.to_s].to_i
  end

  def rating_update_error(tipo, value)
    normalized_tipo = tipo.to_s

    return :invalid_type unless valid_rating_type?(normalized_tipo)
    return :invalid_value unless valid_rating_value?(value)
    return :type_not_available unless rating_type_available?(normalized_tipo)

    nil
  end

  def update_rating(tipo, value)
    return false if rating_update_error(tipo, value)

    current = ratings_hash
    current[tipo.to_s] = value.to_i
    update(ratings: current.to_json)
  end

  def tipo_nuevo
    DiaryDayConfig.new_type_for(day_number)
  end

  def reflexion_day?
    DiaryDayConfig.reflection_day?(day_number)
  end

  def micropausa_day?
    DiaryDayConfig.micropause_day?(day_number)
  end

  def last_day?
    DiaryDayConfig.last_day?(day_number)
  end

  def pausa_sugerida
    DiaryDayConfig.suggested_pause_for(day_number)
  end

  private

  def valid_rating_type?(tipo)
    DiaryDayConfig.type_labels.key?(tipo)
  end

  def valid_rating_value?(value)
    (1..5).include?(value.to_i)
  end

  def rating_type_available?(tipo)
    tipos_disponibles.include?(tipo)
  end
end

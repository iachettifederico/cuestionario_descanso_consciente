# frozen_string_literal: true

class SummariesController < ApplicationController
  before_action :require_authentication
  layout "diario"

  def show # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    @completed_days = current_user.diary_entries.where(saved: true).pluck(:day_number)
    @fatigue_avgs   = current_user.fatigue_averages
    @sleep_avg      = current_user.sleep_average
    @day15          = current_user.entry_for(15)
    @top_tipo       = @fatigue_avgs.max_by { |_, v| v }&.first

    @pausa_estrella = @day15&.pausa_estrella.presence ||
                      current_user.diary_entries
                                  .where.not(micropausa: [nil, ""])
                                  .order(day_number: :desc)
                                  .first&.micropausa&.truncate(120)

    @sorted_tipos = DiaryEntry::TIPO_LABELS.keys.sort_by { |k| -(@fatigue_avgs[k] || 0) }
  end
end

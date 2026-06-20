# frozen_string_literal: true

class DiaryEntrySaveFlow
  Result = Struct.new(:success, :redirect_path, :notice, keyword_init: true) do
    def success?
      success
    end
  end

  def initialize(entry:, day:, save_and_next:)
    @entry = entry
    @day = day
    @save_and_next = save_and_next
  end

  def call(entry_params)
    if @entry.update(entry_params.merge(saved: true))
      Result.new(success: true, redirect_path: redirect_path, notice: notice)
    else
      Result.new(success: false)
    end
  end

  private

  def redirect_path
    if @save_and_next && @day < 15
      Rails.application.routes.url_helpers.diary_day_path(@day + 1)
    elsif @day == 15
      Rails.application.routes.url_helpers.summary_path
    else
      Rails.application.routes.url_helpers.diary_day_path(@day)
    end
  end

  def notice
    if @day == 15
      "¡Completaste los 15 días! 🎉"
    else
      "Día #{@day} guardado ✓"
    end
  end
end

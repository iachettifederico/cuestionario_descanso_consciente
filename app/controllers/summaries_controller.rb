# frozen_string_literal: true

class SummariesController < ApplicationController
  before_action :require_authentication
  layout "diario"

  def show
    @summary = DiarySummary.new(user: current_user)
    @completed_days = @summary.completed_days
    @fatigue_avgs = @summary.fatigue_averages
    @sleep_avg = @summary.sleep_average
    @day15 = @summary.day15_entry
    @top_tipo = @summary.top_tipo
    @pausa_estrella = @summary.pausa_estrella
    @sorted_tipos = @summary.sorted_tipos
  end
end

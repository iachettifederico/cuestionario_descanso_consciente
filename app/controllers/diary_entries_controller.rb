# frozen_string_literal: true

class DiaryEntriesController < ApplicationController
  before_action :require_authentication
  before_action :set_day, only: %i[show save update_rating]
  before_action :set_entry, only: %i[show save update_rating]

  layout "diario"

  def index
    redirect_to diary_day_path(current_user.next_pending_day)
  end

  def show
    @completed_days = current_user.diary_entries.where(saved: true).pluck(:day_number)
  end

  def save
    result = DiaryEntrySaveFlow.new(
      entry: @entry,
      day: @day,
      save_and_next: params[:commit] == "save_and_next"
    ).call(entry_params)

    if result.success?
      redirect_to result.redirect_path, notice: result.notice
    else
      @completed_days = current_user.diary_entries.where(saved: true).pluck(:day_number)
      render :show, status: :unprocessable_entity
    end
  end

  def update_rating
    result = DiaryEntryRatingUpdate.new(
      entry: @entry,
      tipo: params[:tipo],
      valor: params[:valor]
    ).call

    render json: result.payload, status: result.status
  end

  private

  def set_day
    @day = params[:day].to_i
    redirect_to diary_path unless (1..15).include?(@day)
  end

  def set_entry
    @entry = current_user.entry_for(@day) ||
             current_user.diary_entries.build(day_number: @day)
  end

  def entry_params
    params.expect(diary_entry: %i[
                    fecha palabra
                    hora_dormir horas_dormidas calidad_sueno
                    tipo_alto
                    sensacion reflexion micropausa
                    reflexion_final pausa_estrella proximo_foco rutina
                  ])
  end
end

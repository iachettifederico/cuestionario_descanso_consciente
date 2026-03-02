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

  def save # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    save_and_next = params[:commit] == "save_and_next"

    if @entry.update(entry_params.merge(saved: true))
      if save_and_next && @day < 15
        redirect_to diary_day_path(@day + 1), notice: "Día #{@day} guardado ✓"
      elsif @day == 15
        redirect_to summary_path, notice: "¡Completaste los 15 días! 🎉" # rubocop:disable Rails/I18nLocaleTexts
      else
        redirect_to diary_day_path(@day), notice: "Día #{@day} guardado ✓"
      end
    else
      @completed_days = current_user.diary_entries.where(saved: true).pluck(:day_number)
      render :show, status: :unprocessable_entity
    end
  end

  def update_rating # rubocop:disable Metrics/MethodLength
    tipo  = params[:tipo].to_s
    valor = params[:valor].to_i

    unless DiaryEntry::TIPO_LABELS.key?(tipo) && (1..5).include?(valor)
      render json: { error: "Parámetros inválidos" }, status: :unprocessable_entity
      return
    end

    unless @entry.tipos_disponibles.include?(tipo)
      render json: { error: "Tipo no disponible para este día" }, status: :unprocessable_entity
      return
    end

    if @entry.update_rating(tipo, valor)
      render json: { ok: true }
    else
      render json: { error: "No se pudo guardar" }, status: :unprocessable_entity
    end
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

# frozen_string_literal: true

class DiaryEntryRatingUpdate
  Result = Struct.new(:payload, :status, keyword_init: true) do
    def success?
      status == :ok
    end
  end

  def initialize(entry:, tipo:, valor:)
    @entry = entry
    @tipo = tipo.to_s
    @valor = valor.to_i
  end

  def call
    case @entry.rating_update_error(@tipo, @valor)
    when :invalid_type, :invalid_value
      Result.new(payload: { error: "Parámetros inválidos" }, status: :unprocessable_entity)
    when :type_not_available
      Result.new(payload: { error: "Tipo no disponible para este día" }, status: :unprocessable_entity)
    else
      if @entry.update_rating(@tipo, @valor)
        Result.new(payload: { ok: true }, status: :ok)
      else
        Result.new(payload: { error: "No se pudo guardar" }, status: :unprocessable_entity)
      end
    end
  end
end

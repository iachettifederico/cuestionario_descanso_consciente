# frozen_string_literal: true

class CreateDiaryEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :diary_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.integer  :day_number, null: false
      t.date     :fecha
      t.string   :palabra
      t.text     :ratings, default: "{}"
      t.string   :hora_dormir
      t.decimal  :horas_dormidas, precision: 4, scale: 1
      t.string   :calidad_sueno
      t.string   :tipo_alto
      t.text     :sensacion
      t.text     :reflexion
      t.text     :micropausa
      t.text     :reflexion_final
      t.string   :pausa_estrella
      t.string   :proximo_foco
      t.text     :rutina
      t.boolean  :saved, default: false
      t.timestamps
    end

    add_index :diary_entries, %i[user_id day_number], unique: true
  end
end

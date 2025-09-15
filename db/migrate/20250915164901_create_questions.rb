# frozen_string_literal: true

class CreateQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :questions do |t|
      t.text :text, null: false
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
  end
end

# frozen_string_literal: true

class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false, limit: 100
      t.string :identifier, null: false, limit: 50
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :categories, :identifier, unique: true
    add_index :categories, :position
  end
end

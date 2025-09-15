# frozen_string_literal: true

class Category < ApplicationRecord
  has_many :questions, dependent: :destroy

  validates :name, presence: true
  validates :identifier, presence: true, uniqueness: true
end

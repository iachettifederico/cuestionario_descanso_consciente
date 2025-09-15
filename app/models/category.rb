# frozen_string_literal: true

class Category < ApplicationRecord
  has_many :questions, -> { order(:position) }, dependent: :destroy, inverse_of: :category

  validates :name, presence: true
  validates :identifier, presence: true, uniqueness: true
  validates :position, presence: true

  scope :ordered, -> { order(:position) }

  def to_param
    identifier
  end
end

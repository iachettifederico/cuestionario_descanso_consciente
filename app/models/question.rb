# frozen_string_literal: true

class Question < ApplicationRecord
  belongs_to :category

  validates :text, presence: true
end

# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require "yaml"

# Load tiredness questionnaire data
questionnaire_data = YAML.load_file(Rails.root.join("docs/cansancios.yml"))

questionnaire_data.each do |category_data|
  category = Category.find_or_create_by!(identifier: category_data["id"]) { |c|
    c.name = category_data["name"]
  }

  category_data["questions"].each do |question_text|
    category.questions.find_or_create_by!(text: question_text)
  end
end

puts "Created #{Category.count} categories with #{Question.count} questions total"

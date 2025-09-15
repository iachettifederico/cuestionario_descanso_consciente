# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require "yaml"

# Category descriptions based on Dr. Saundra Dalton-Smith's 7 types of rest
category_descriptions = {
  "fisico"     => "El descanso físico se refiere a la necesidad de relajar y restaurar tu cuerpo. Incluye tanto el sueño reparador como actividades de relajación que permiten que tus músculos y sistemas corporales se recuperen del estrés diario.",
  "mental"     => "El descanso mental es esencial para dar un respiro a tu mente del constante procesamiento de información. Se trata de desconectar del análisis, la toma de decisiones y el trabajo cognitivo intenso.",
  "emocional"  => "El descanso emocional implica liberarte de la necesidad de complacer a otros y de gestionar constantemente las emociones propias y ajenas. Es permitirte ser auténtico sin filtros emocionales.",
  "sensorial"  => "El descanso sensorial consiste en reducir la sobreestimulación de tus sentidos. En nuestro mundo lleno de pantallas, ruidos y estímulos constantes, este tipo de descanso es crucial.",
  "social"     => "El descanso social significa alejarte de interacciones que drenan tu energía y buscar conexiones que te nutren y restauran. No se trata de aislarse, sino de elegir conscientemente con quién y cómo interactúas.",
  "espiritual" => "El descanso espiritual va más allá de la religión; se trata de conectar con un propósito mayor, sentir que perteneces a algo más grande que tú mismo y encontrar significado en tu existencia.",
  "creativo"   => "El descanso creativo se obtiene al exponerte a la belleza y la inspiración, permitiendo que tu mente se maraville y se inspire. Es esencial para la innovación y la resolución de problemas.",
}

# Load tiredness questionnaire data
questionnaire_data = YAML.load_file(Rails.root.join("docs/cansancios.yml"))

questionnaire_data.each_with_index do |category_data, category_index|
  category = Category.find_or_create_by!(identifier: category_data["identifier"]) { |c|
    c.name = category_data["name"]
    c.description = category_descriptions[category_data["identifier"]]
    c.position = category_index
  }

  # Update description if category already exists
  if category.description.blank? && category_descriptions[category_data["identifier"]]
    category.update!(description: category_descriptions[category_data["identifier"]])
  end

  category_data["questions"].each_with_index do |question_text, question_index|
    category.questions.find_or_create_by!(text: question_text) do |q|
      q.position = question_index
    end
  end
end

puts "Created #{Category.count} categories with #{Question.count} questions total"

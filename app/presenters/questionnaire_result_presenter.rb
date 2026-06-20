# frozen_string_literal: true

class QuestionnaireResultPresenter
  HIGH_THRESHOLD = 60
  MODERATE_THRESHOLD = 40
  MAX_SCORE = 18

  def initialize(categories:, category_scores:, predominant_tiredness:)
    @categories = categories
    @category_scores = category_scores
    @predominant_tiredness = predominant_tiredness
  end

  attr_reader :predominant_tiredness

  def total_responses
    category_scores.values.sum
  end

  def sorted_categories
    categories.sort_by { |category| -score_for(category) }
  end

  def score_for(category)
    category_scores[category.id].to_i
  end

  def percentage_for(category)
    (score_for(category).to_f / MAX_SCORE * 100).round
  end

  def category_color_class(category, pdf: false)
    return "border-coral" if pdf && high_score?(category)
    return "border-yellow" if pdf && moderate_score?(category)
    return "border-green-light" if pdf

    if high_score?(category)
      "border-coral hover:border-coral"
    elsif moderate_score?(category)
      "border-yellow hover:border-yellow-600"
    else
      "border-green-light hover:border-green"
    end
  end

  def badge_color_class(category)
    if high_score?(category)
      "bg-coral text-white"
    elsif moderate_score?(category)
      "bg-yellow-400 text-gray-800"
    else
      "bg-green-light text-white"
    end
  end

  def progress_bar_color(category)
    if high_score?(category)
      "progress-bar high"
    elsif moderate_score?(category)
      "progress-bar moderate"
    else
      "progress-bar good"
    end
  end

  def recommendation_text(category)
    if high_score?(category)
      "Este tipo de cansancio está afectando seriamente tu bienestar. Te recomendamos priorizar los descansos específicos para esta área."
    elsif moderate_score?(category)
      "Es probable que necesites revisar y mejorar tu descanso en esta área."
    else
      "Estás manejando bien tu descanso en esta área."
    end
  end

  private

  attr_reader :categories, :category_scores

  def high_score?(category)
    percentage_for(category) >= HIGH_THRESHOLD
  end

  def moderate_score?(category)
    percentage_for(category) >= MODERATE_THRESHOLD
  end
end

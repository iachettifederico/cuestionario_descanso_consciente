# frozen_string_literal: true

class QuestionnaireFlow
  attr_reader :params, :session

  def initialize(params:, session:)
    @params = params
    @session = session
  end

  def categories
    @categories ||= Category.ordered.includes(:questions)
  end

  def category
    @category ||= find_category
  end

  def previous_category
    return nil unless params[:category_id]

    categories.where(position: ...category.position).last
  end

  def next_category
    return nil unless category

    categories.where("position > ?", category.position).first
  end

  def current_category_position
    category.position + 1
  end

  def answers
    session[:questionnaire_answers] ||= {}
  end

  def all_questions_answered?
    return false unless params[:answers]

    category.questions.all? do |question|
      params[:answers][question.id.to_s].present?
    end
  end

  def store_answers!
    params[:answers]&.each do |question_id, answer|
      answers[question_id] = answer.to_i
    end
  end

  def category_scores
    categories.each_with_object({}) do |current_category, scores|
      scores[current_category.id] = current_category.questions.sum do |question|
        answers[question.id.to_s].to_i
      end
    end
  end

  def predominant_tiredness
    scores = category_scores
    return nil if scores.empty?

    max_score = scores.values.max
    return nil if max_score.zero?

    categories.find { |current_category| scores[current_category.id] == max_score }
  end

  private

  def find_category
    if params[:category_id]
      Category.find_by!(identifier: params[:category_id])
    else
      categories.first
    end
  end
end

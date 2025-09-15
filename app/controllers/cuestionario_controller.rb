# frozen_string_literal: true

class CuestionarioController < ApplicationController
  def welcome
  end

  def show
    @category = find_category
    @categories = Category.ordered
    @answers = session[:questionnaire_answers] || {}
    @previous_category = find_previous_category
    @next_category = find_next_category
    @current_category_position = @category.position + 1
  end

  def submit
    category = find_category
    session[:questionnaire_answers] ||= {}

    return redirect_with_error(category) unless all_questions_answered?(category)

    store_answers
    redirect_to_next_category(category)
  end

  def formulario
  end

  def resultados
    @answers = session[:questionnaire_answers] || {}
    @categories = Category.ordered.includes(:questions)
    @category_scores = calculate_category_scores
    @predominant_tiredness = find_predominant_tiredness
  end

  private

  def find_category
    if params[:category_id]
      Category.find_by!(identifier: params[:category_id])
    else
      Category.ordered.first
    end
  end

  def find_previous_category
    return nil unless params[:category_id]

    current_category = Category.find_by(identifier: params[:category_id])
    return nil unless current_category

    Category.ordered.where(position: ...current_category.position).last
  end

  def find_next_category
    return nil unless @category

    Category.ordered.where("position > ?", @category.position).first
  end

  def all_questions_answered?(category)
    return false unless params[:answers]

    category.questions.all? do |question|
      params[:answers][question.id.to_s].present?
    end
  end

  def calculate_category_scores
    scores = {}
    @categories.each do |category|
      scores[category.id] = category.questions.sum { |question|
        @answers[question.id.to_s].to_i
      }
    end
    scores
  end

  def redirect_with_error(category)
    flash[:alert] = I18n.t("questionnaire.validation.all_questions_required")
    redirect_to cuestionario_category_path(category.identifier)
  end

  def store_answers
    params[:answers]&.each do |question_id, answer|
      session[:questionnaire_answers][question_id] = answer.to_i
    end
  end

  def redirect_to_next_category(category)
    next_category = Category.ordered.where("position > ?", category.position).first

    if next_category
      redirect_to cuestionario_category_path(next_category.identifier)
    else
      redirect_to "/cuestionario/formulario"
    end
  end

  def find_predominant_tiredness
    return nil if @category_scores.empty?

    max_score = @category_scores.values.max
    return nil if max_score.zero?

    category_id = @category_scores.key(max_score)
    @categories.find { |category| category.id == category_id }
  end
end

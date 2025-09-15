# frozen_string_literal: true

class CuestionarioController < ApplicationController
  def show
    @category = find_category
    @categories = Category.ordered
    @answers = session[:questionnaire_answers] || {}
    @previous_category = find_previous_category
  end

  def submit
    category = find_category
    session[:questionnaire_answers] ||= {}

    unless all_questions_answered?(category)
      flash[:alert] = "Por favor responde todas las preguntas antes de continuar"
      redirect_to cuestionario_category_path(category.identifier)
      return
    end

    params[:answers]&.each do |question_id, answer|
      session[:questionnaire_answers][question_id] = answer.to_i
    end

    next_category = Category.ordered.where("position > ?", category.position).first

    if next_category
      redirect_to cuestionario_category_path(next_category.identifier)
    else
      redirect_to "/cuestionario/formulario"
    end
  end

  def formulario
  end

  def resultados
    @answers = session[:questionnaire_answers] || {}
    @categories = Category.ordered.includes(:questions)
    @category_scores = calculate_category_scores
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

    Category.ordered.where("position < ?", current_category.position).last
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
end

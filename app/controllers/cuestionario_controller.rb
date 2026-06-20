# frozen_string_literal: true

class CuestionarioController < ApplicationController
  allow_unauthenticated_access

  def welcome
  end

  def show
    assign_questionnaire_state
  end

  def submit
    return redirect_with_error(flow.category) unless flow.all_questions_answered?

    flow.store_answers!
    redirect_to_next_category
  end

  def formulario
  end

  def resultados
    assign_questionnaire_results
  end

  def descargar_resultados
    assign_questionnaire_results

    render layout: "pdf"
  end

  # Developer tools methods (only available in development)
  def fill_random_answers
    return head :not_found unless Rails.env.development?

    session[:questionnaire_answers] = {}
    Question.find_each do |question|
      session[:questionnaire_answers][question.id.to_s] = rand(0..3)
    end

    flash[:notice] = "🎲 Todas las preguntas completadas con valores aleatorios"
    redirect_back(fallback_location: "/cuestionario")
  end

  def fill_random_current
    return head :not_found unless Rails.env.development?

    # Use the category_id from the form params if provided
    category = if params[:category_id].present?
                 Category.find_by!(identifier: params[:category_id])
               else
                 find_category
               end

    session[:questionnaire_answers] ||= {}

    filled_count = 0
    category.questions.each do |question|
      session[:questionnaire_answers][question.id.to_s] = rand(0..3)
      filled_count += 1
    end

    flash[:notice] = "🎲 #{category.name} completada (#{filled_count} preguntas)"

    # Try to redirect to the same category page if we have the identifier
    if params[:category_id].present?
      redirect_to cuestionario_category_path(params[:category_id])
    else
      redirect_back(fallback_location: "/cuestionario")
    end
  end

  def clear_session
    return head :not_found unless Rails.env.development?

    session[:questionnaire_answers] = {}
    flash[:notice] = "🗑️ Sesión limpiada exitosamente"
    redirect_back(fallback_location: "/cuestionario")
  end

  def show_results_with_random
    return head :not_found unless Rails.env.development?

    # Fill any missing answers with random values
    session[:questionnaire_answers] ||= {}
    Question.find_each do |question|
      session[:questionnaire_answers][question.id.to_s] ||= rand(0..3)
    end

    redirect_to "/cuestionario/resultados"
  end

  private

  def flow
    @flow ||= QuestionnaireFlow.new(params: params, session: session)
  end

  def assign_questionnaire_state
    @category = flow.category
    @categories = flow.categories
    @answers = flow.answers
    @previous_category = flow.previous_category
    @next_category = flow.next_category
    @current_category_position = flow.current_category_position
  end

  def redirect_with_error(category)
    flash[:alert] = I18n.t("questionnaire.validation.all_questions_required")
    redirect_to cuestionario_category_path(category.identifier)
  end

  def redirect_to_next_category
    next_category = flow.next_category

    if next_category
      redirect_to cuestionario_category_path(next_category.identifier)
    else
      redirect_to "/cuestionario/formulario"
    end
  end

  def assign_questionnaire_results
    @answers = flow.answers
    @categories = flow.categories
    @category_scores = flow.category_scores
    @predominant_tiredness = flow.predominant_tiredness
  end
end

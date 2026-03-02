# frozen_string_literal: true

Rails.application.routes.draw do
  # ─── DIARIO (autenticado) ───────────────────────────────────────────
  get    "sign_in",  to: "sessions#new", as: :sign_in
  post   "sign_in",  to: "sessions#create"
  delete "sign_out", to: "sessions#destroy",     as: :sign_out
  get    "sign_up",  to: "registrations#new",    as: :sign_up
  post   "sign_up",  to: "registrations#create"

  get   "diario",              to: "diary_entries#index",         as: :diary
  get   "diario/resumen",      to: "summaries#show",              as: :summary
  get   "diario/:day",         to: "diary_entries#show",          as: :diary_day,
        constraints: { day: /([1-9]|1[0-5])/ }
  post  "diario/:day",         to: "diary_entries#save",          as: :save_diary_day
  patch "diario/:day/rating",  to: "diary_entries#update_rating", as: :update_rating

  # ─── CUESTIONARIO (público) ─────────────────────────────────────────
  get "up" => "rails/health#show", as: :rails_health_check

  root to: "home#index"
  get "cuestionario", to: "cuestionario#welcome"
  get "cuestionario/comenzar", to: "cuestionario#show"
  get "cuestionario/formulario", to: "cuestionario#formulario"
  get "cuestionario/resultados", to: "cuestionario#resultados"
  get "cuestionario/descargar", to: "cuestionario#descargar_resultados"

  if Rails.env.development?
    post "cuestionario/dev/fill_random", to: "cuestionario#fill_random_answers"
    post "cuestionario/dev/fill_random_current", to: "cuestionario#fill_random_current"
    delete "cuestionario/dev/clear", to: "cuestionario#clear_session"
    get "cuestionario/dev/show_results", to: "cuestionario#show_results_with_random"
  end

  get  "cuestionario/:category_id", to: "cuestionario#show", as: :cuestionario_category
  post "cuestionario/:category_id", to: "cuestionario#submit"
end

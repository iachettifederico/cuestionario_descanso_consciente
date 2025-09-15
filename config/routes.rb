# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root to: redirect("/cuestionario")
  get "cuestionario", to: "cuestionario#welcome"
  get "cuestionario/comenzar", to: "cuestionario#show"
  get "cuestionario/formulario", to: "cuestionario#formulario"
  get "cuestionario/resultados", to: "cuestionario#resultados"

  # Developer tools (only in development) - must come before catch-all routes
  if Rails.env.development?
    post "cuestionario/dev/fill_random", to: "cuestionario#fill_random_answers"
    post "cuestionario/dev/fill_random_current", to: "cuestionario#fill_random_current"
    delete "cuestionario/dev/clear", to: "cuestionario#clear_session"
    get "cuestionario/dev/show_results", to: "cuestionario#show_results_with_random"
  end

  get "cuestionario/:category_id", to: "cuestionario#show", as: :cuestionario_category
  post "cuestionario/:category_id", to: "cuestionario#submit"
end

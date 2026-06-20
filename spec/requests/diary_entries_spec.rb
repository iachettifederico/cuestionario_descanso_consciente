# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DiaryEntries", type: :request do
  let(:user) do
    User.create!(
      name: "Test User",
      email_address: "user@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  let(:login_params) do
    { email_address: user.email_address, password: "password" }
  end

  def sign_in
    post sign_in_path, params: login_params
  end

  it "redirects anonymous users to sign in" do
    get diary_path

    expect(response).to redirect_to(sign_in_path)
  end

  it "redirects signed-in users to the next pending day" do
    sign_in
    get diary_path

    expect(response).to redirect_to(diary_day_path(1))
  end

  it "shows a diary day for signed-in users" do
    sign_in
    get diary_day_path(1)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Diario de")
  end

  it "saves a day and continues when requested" do
    sign_in

    post save_diary_day_path(1), params: {
      commit: "save_and_next",
      diary_entry: {
        fecha: "2026-06-20",
        palabra: "cansancio",
        hora_dormir: "22:30",
        horas_dormidas: "7.5",
        calidad_sueno: "Buena",
        tipo_alto: "fisico",
        sensacion: "bien",
        reflexion: "",
        micropausa: "",
        reflexion_final: "",
        pausa_estrella: "",
        proximo_foco: "",
        rutina: ""
      }
    }

    expect(response).to redirect_to(diary_day_path(2))
    expect(DiaryEntry.find_by(user: user, day_number: 1)&.saved).to be(true)
  end

  it "saves the final day and redirects to the summary" do
    sign_in

    post save_diary_day_path(15), params: {
      diary_entry: {
        fecha: "2026-06-20",
        palabra: "cierre",
        hora_dormir: "22:30",
        horas_dormidas: "7.5",
        calidad_sueno: "Buena",
        tipo_alto: "fisico",
        reflexion: "",
        micropausa: "",
        reflexion_final: "Aprendí a frenar",
        pausa_estrella: "Respirar",
        proximo_foco: "Descanso físico",
        rutina: "Salir a caminar"
      }
    }

    expect(response).to redirect_to(summary_path)
    expect(DiaryEntry.find_by(user: user, day_number: 15)&.saved).to be(true)
  end

  it "updates a rating through the JSON endpoint" do
    sign_in

    patch update_rating_path(1), params: { tipo: "fisico", valor: 4 }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq({ "ok" => true })
    expect(DiaryEntry.find_by(user: user, day_number: 1)&.rating_for("fisico")).to eq(4)
  end

  it "rejects invalid rating types" do
    sign_in

    patch update_rating_path(1), params: { tipo: "bogus", valor: 4 }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body).to eq({ "error" => "Parámetros inválidos" })
  end

  it "rejects invalid rating values" do
    sign_in

    patch update_rating_path(1), params: { tipo: "fisico", valor: 0 }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body).to eq({ "error" => "Parámetros inválidos" })
  end

  it "rejects rating types unavailable for the day" do
    sign_in

    patch update_rating_path(1), params: { tipo: "mental", valor: 4 }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body).to eq({ "error" => "Tipo no disponible para este día" })
  end
end

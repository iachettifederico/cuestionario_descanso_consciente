# Implementación: Diario de Cansancio

## Contexto del proyecto actual

Este es un proyecto Rails 8 existente que ya tiene:
- Cuestionario de 7 tipos de cansancio en `/cuestionario` (público, sin auth)
- Modelos `Category` y `Question` (sin cambios)
- `ApplicationController` sin autenticación aún
- Tailwind CSS v4 con Propshaft e Importmap
- Gemas ya instaladas: `bcrypt` (lista para auth), `turbo-rails`, `stimulus-rails`
- Rutas existentes bajo `/cuestionario`
- Layout existente en `app/views/layouts/application.html.erb`
- Stimulus controllers existentes en `app/javascript/controllers/`

**Importante:** No tocar nada de lo existente del cuestionario. Agregar el diario como una sección nueva paralela.

---

## Objetivo

Agregar el **"Diario de Cansancio"** — una app de autoregistro de 15 días con autenticación — al mismo proyecto Rails, conviviendo con el cuestionario existente.

---

## Paso 1: Generar autenticación de Rails 8

```bash
bin/rails generate authentication
```

Esto genera automáticamente:
- Modelo `User` con `email_address` y `password_digest`
- Modelo `Session`
- Modelo `Current`
- `SessionsController` base
- Módulo `Authentication` con `require_authentication`, `allow_unauthenticated_access`, `authenticated?`, `start_new_session_for`, `Current.user`
- Migraciones para `users` y `sessions`

**Después de generar**, agregar a `User` el campo `name` con una migración adicional (ver Paso 2).

---

## Paso 2: Migración para `name` en `users`

```ruby
# db/migrate/TIMESTAMP_add_name_to_users.rb
# frozen_string_literal: true

class AddNameToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string, null: false, default: ""
  end
end
```

---

## Paso 3: Migración para `diary_entries`

```ruby
# db/migrate/TIMESTAMP_create_diary_entries.rb
# frozen_string_literal: true

class CreateDiaryEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :diary_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.integer  :day_number,     null: false
      t.date     :fecha
      t.string   :palabra
      t.text     :ratings,        default: "{}"
      t.string   :hora_dormir
      t.decimal  :horas_dormidas, precision: 4, scale: 1
      t.string   :calidad_sueno
      t.string   :tipo_alto
      t.text     :sensacion
      t.text     :reflexion
      t.text     :micropausa
      t.text     :reflexion_final
      t.string   :pausa_estrella
      t.string   :proximo_foco
      t.text     :rutina
      t.boolean  :saved,         default: false
      t.timestamps
    end

    add_index :diary_entries, %i[user_id day_number], unique: true
  end
end
```

Ejecutar: `bin/rails db:migrate`

---

## Paso 4: Modelo `User`

Reemplazar el `User` generado por Rails authentication con este (mantiene `has_secure_password` que ya incluyó el generator):

```ruby
# app/models/user.rb
# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  has_many :diary_entries, dependent: :destroy
  has_many :sessions, dependent: :destroy

  validates :email_address, presence: true,
                            uniqueness: true,
                            format: { :with => URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  normalizes :email_address, :with => ->(e) { e.strip.downcase }

  def entry_for(day)
    diary_entries.find_by(:day_number => day)
  end

  def completed_days
    diary_entries.where(:saved => true).count
  end

  def next_pending_day
    completed = diary_entries.where(:saved => true).pluck(:day_number)
    (1..15).find { |d| !completed.include?(d) } || 15
  end

  def fatigue_averages
    entries = diary_entries.where.not(:ratings => [nil, "{}"])
    sums = Hash.new(0)
    counts = Hash.new(0)

    entries.each do |entry|
      begin
        ratings = JSON.parse(entry.ratings)
      rescue JSON::ParserError
        ratings = {}
      end
      ratings.each do |tipo, val|
        next unless val.to_i > 0

        sums[tipo] += val.to_i
        counts[tipo] += 1
      end
    end

    averages = {}
    sums.each do |tipo, sum|
      averages[tipo] = (sum.to_f / counts[tipo]).round(1)
    end
    averages
  end

  def sleep_average
    entries = diary_entries.where.not(:horas_dormidas => nil)
    return nil if entries.empty?

    (entries.sum(:horas_dormidas) / entries.count).round(1)
  end
end
```

**Nota:** `has_many :sessions` debe incluirse porque el generator de Rails 8 crea el modelo `Session` con `belongs_to :user`.

---

## Paso 5: Modelo `DiaryEntry`

```ruby
# app/models/diary_entry.rb
# frozen_string_literal: true

class DiaryEntry < ApplicationRecord
  belongs_to :user

  validates :day_number, presence: true, inclusion: { :in => 1..15 }
  validates :user_id, uniqueness: { :scope => :day_number }

  TIPOS_POR_DIA = {
    1  => %w[fisico],
    2  => %w[fisico],
    3  => %w[fisico mental],
    4  => %w[fisico mental],
    5  => %w[fisico mental emocional],
    6  => %w[fisico mental emocional],
    7  => %w[fisico mental emocional sensorial],
    8  => %w[fisico mental emocional sensorial],
    9  => %w[fisico mental emocional sensorial social],
    10 => %w[fisico mental emocional sensorial social],
    11 => %w[fisico mental emocional sensorial social creativo],
    12 => %w[fisico mental emocional sensorial social creativo],
    13 => %w[fisico mental emocional sensorial social creativo espiritual],
    14 => %w[fisico mental emocional sensorial social creativo espiritual],
    15 => %w[fisico mental emocional sensorial social creativo espiritual]
  }.freeze

  TIPO_LABELS = {
    "fisico"     => { :label => "Físico",     :icon => "💪", :desc => "Tu cuerpo necesita movimiento y descanso físico real" },
    "mental"     => { :label => "Mental",     :icon => "🧠", :desc => "Tu mente necesita silencio, límites de información y claridad" },
    "emocional"  => { :label => "Emocional",  :icon => "💚", :desc => "Tu corazón necesita espacio para sentir sin performar" },
    "sensorial"  => { :label => "Sensorial",  :icon => "👁️",  :desc => "Tus sentidos necesitan menos estímulos, menos pantallas" },
    "social"     => { :label => "Social",     :icon => "🤝", :desc => "Tu energía social necesita recarga en soledad o conexión genuina" },
    "creativo"   => { :label => "Creativo",   :icon => "🎨", :desc => "Tu creatividad necesita inspiración o permiso para no producir" },
    "espiritual" => { :label => "Espiritual", :icon => "🌿", :desc => "Tu sentido de propósito necesita reconexión con lo que importa" }
  }.freeze

  PAUSAS_SUGERIDAS = {
    1  => { :icon => "🌬️", :text => "Respiración 4-7-8: inhalá 4 segundos, retené 7, exhalá 8. Repetí 3 veces. Ideal antes de tu próximo paciente." },
    2  => { :icon => "🚶‍♀️", :text => "Caminata de 5 minutos sin teléfono ni destino concreto. Solo mover el cuerpo y observar lo que hay alrededor." },
    3  => { :icon => "📋", :text => "Vaciado mental: anotá durante 3 minutos todo lo que tenés 'abierto' en la mente, sin ordenar. Solo sacar." },
    4  => { :icon => "🧩", :text => "Cierre de pestañas mentales: elegí una tarea inconclusa y definí cuándo la vas a retomar. Liberá ese espacio." },
    5  => { :icon => "🫁", :text => "Pausa de check-in emocional: poné una mano en el pecho, cerrá los ojos y preguntate '¿qué emoción está presente ahora?' Sin juzgar." },
    6  => { :icon => "📓", :text => "3 líneas de descarga emocional: escribí lo que sentís sin corregir, sin releer. Solo sacarlo afuera." },
    7  => { :icon => "🎵", :text => "2 minutos de silencio intencional: apagá pantallas y notificaciones. Simplemente escuchá los sonidos del entorno." },
    8  => { :icon => "👀", :text => "Descanso ocular: cerrá los ojos por 2 minutos con las palmas sobre ellos. Sentí el calor. Nada más." },
    9  => { :icon => "🏡", :text => "Momento de cierre social: antes de llegar a casa, tomá 5 minutos sola en el auto. Sin hablar con nadie." },
    10 => { :icon => "☕", :text => "Pausa sin pantalla: tomá un café o té y no revises el teléfono mientras lo hacés. Solo vos y la bebida." },
    11 => { :icon => "🎨", :text => "Garabato libre: tomá una hoja y un lápiz y dibujá sin objetivo durante 3 minutos. No tiene que significar nada." },
    12 => { :icon => "🌿", :text => "Salida a la naturaleza express: 5 minutos afuera, mirá algo verde o el cielo. Sin auriculares, sin pantallas." },
    13 => { :icon => "🙏", :text => "Momento de gratitud silenciosa: cerrá los ojos y nombrá mentalmente 3 cosas pequeñas de hoy que te hicieron bien." },
    14 => { :icon => "✍️", :text => "Una línea de propósito: escribí en una oración por qué hacés lo que hacés. Solo para recordártelo vos misma." },
    15 => { :icon => "🌸", :text => "Hoy la micro-pausa es esta misma reflexión. Tomarte este tiempo ya es un acto de descanso consciente." }
  }.freeze

  REFLEXION_DAYS  = [2, 4, 6, 8, 10].freeze
  MICROPAUSA_DAYS = [1, 3, 5, 7, 9, 11, 12, 13, 14].freeze

  def tipos_disponibles
    TIPOS_POR_DIA[day_number] || []
  end

  def ratings_hash
    JSON.parse(ratings.presence || "{}") rescue {}
  end

  def rating_for(tipo)
    ratings_hash[tipo.to_s].to_i
  end

  def update_rating(tipo, value)
    current = ratings_hash
    current[tipo.to_s] = value.to_i
    update(:ratings => current.to_json)
  end

  def tipo_nuevo
    return nil unless [3, 5, 7, 9, 11, 13].include?(day_number)

    tipos_disponibles.last
  end

  def reflexion_day?
    REFLEXION_DAYS.include?(day_number)
  end

  def micropausa_day?
    MICROPAUSA_DAYS.include?(day_number)
  end

  def last_day?
    day_number == 15
  end

  def pausa_sugerida
    PAUSAS_SUGERIDAS[day_number]
  end
end
```

---

## Paso 6: Modificar `ApplicationController`

El `ApplicationController` existente solo tiene `allow_browser versions: :modern`. Hay que incluir el módulo `Authentication` que generó Rails, pero **sin** poner `before_action :require_authentication` como default global (porque el cuestionario es público).

```ruby
# app/controllers/application_controller.rb
# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def current_user = Current.user
  helper_method :current_user
end
```

**No agregar** `before_action :require_authentication` aquí globalmente. Cada controlador del diario lo hará individualmente.

---

## Paso 7: Controladores del diario

### `RegistrationsController`

```ruby
# app/controllers/registrations_controller.rb
# frozen_string_literal: true

class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  layout "diario"

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for(@user)
      redirect_to diary_path, notice: "¡Bienvenida! Tu diario de 15 días está listo para comenzar."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email_address, :password, :password_confirmation)
  end
end
```

### `DiaryEntriesController`

```ruby
# app/controllers/diary_entries_controller.rb
# frozen_string_literal: true

class DiaryEntriesController < ApplicationController
  before_action :require_authentication
  before_action :set_day, only: %i[show save update_rating]
  before_action :set_entry, only: %i[show save update_rating]

  layout "diario"

  def index
    redirect_to diary_day_path(current_user.next_pending_day)
  end

  def show
    @completed_days = current_user.diary_entries.where(:saved => true).pluck(:day_number)
  end

  def save
    save_and_next = params[:commit] == "save_and_next"

    if @entry.update(entry_params.merge(:saved => true))
      if save_and_next && @day < 15
        redirect_to diary_day_path(@day + 1), notice: "Día #{@day} guardado ✓"
      elsif @day == 15
        redirect_to summary_path, notice: "¡Completaste los 15 días! 🎉"
      else
        redirect_to diary_day_path(@day), notice: "Día #{@day} guardado ✓"
      end
    else
      @completed_days = current_user.diary_entries.where(:saved => true).pluck(:day_number)
      render :show, status: :unprocessable_entity
    end
  end

  def update_rating
    tipo  = params[:tipo].to_s
    valor = params[:valor].to_i

    unless DiaryEntry::TIPO_LABELS.key?(tipo) && (1..5).include?(valor)
      render json: { :error => "Parámetros inválidos" }, status: :unprocessable_entity
      return
    end

    unless @entry.tipos_disponibles.include?(tipo)
      render json: { :error => "Tipo no disponible para este día" }, status: :unprocessable_entity
      return
    end

    if @entry.update_rating(tipo, valor)
      render json: { :ok => true }
    else
      render json: { :error => "No se pudo guardar" }, status: :unprocessable_entity
    end
  end

  private

  def set_day
    @day = params[:day].to_i
    redirect_to diary_path unless (1..15).include?(@day)
  end

  def set_entry
    @entry = current_user.entry_for(@day) ||
             current_user.diary_entries.build(:day_number => @day)
  end

  def entry_params
    params.require(:diary_entry).permit(
      :fecha, :palabra,
      :hora_dormir, :horas_dormidas, :calidad_sueno,
      :tipo_alto,
      :sensacion, :reflexion, :micropausa,
      :reflexion_final, :pausa_estrella, :proximo_foco, :rutina
    )
  end
end
```

### `SummariesController`

```ruby
# app/controllers/summaries_controller.rb
# frozen_string_literal: true

class SummariesController < ApplicationController
  before_action :require_authentication
  layout "diario"

  def show
    @completed_days = current_user.diary_entries.where(:saved => true).pluck(:day_number)
    @fatigue_avgs   = current_user.fatigue_averages
    @sleep_avg      = current_user.sleep_average
    @day15          = current_user.entry_for(15)
    @top_tipo       = @fatigue_avgs.max_by { |_, v| v }&.first

    @pausa_estrella = @day15&.pausa_estrella.presence ||
                      current_user.diary_entries
                                  .where.not(:micropausa => [nil, ""])
                                  .order(:day_number => :desc)
                                  .first&.micropausa&.truncate(120)

    @sorted_tipos = DiaryEntry::TIPO_LABELS.keys.sort_by { |k| -(@fatigue_avgs[k] || 0) }
  end
end
```

---

## Paso 8: Rutas

Reemplazar `config/routes.rb` manteniendo todo lo existente del cuestionario y agregando las rutas del diario:

```ruby
# config/routes.rb
# frozen_string_literal: true

Rails.application.routes.draw do
  # ─── DIARIO (autenticado) ───────────────────────────────────────────
  get    "sign_in",  to: "sessions#new",         as: :sign_in
  post   "sign_in",  to: "sessions#create"
  delete "sign_out", to: "sessions#destroy",     as: :sign_out
  get    "sign_up",  to: "registrations#new",    as: :sign_up
  post   "sign_up",  to: "registrations#create"

  get   "diario",              to: "diary_entries#index",        as: :diary
  get   "diario/resumen",      to: "summaries#show",             as: :summary
  get   "diario/:day",         to: "diary_entries#show",         as: :diary_day,
        constraints: { :day => /([1-9]|1[0-5])/ }
  post  "diario/:day",         to: "diary_entries#save",         as: :save_diary_day
  patch "diario/:day/rating",  to: "diary_entries#update_rating", as: :update_rating

  # ─── CUESTIONARIO (público) ─────────────────────────────────────────
  get "up" => "rails/health#show", as: :rails_health_check

  root to: redirect("/cuestionario")
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
```

**Importante:** La ruta `diario/resumen` debe ir **antes** de `diario/:day` para que no sea capturada por el pattern dinámico.

---

## Paso 9: Layout del diario

Crear `app/views/layouts/diario.html.erb`:

```erb
<!DOCTYPE html>
<html lang="es">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= content_for(:title) { "Diario de Cansancio · Tu Pausa, Tu Esencia" } %></title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,500;1,300;1,400;1,600&family=DM+Sans:ital,wght@0,300;0,400;0,500;1,300&display=swap" rel="stylesheet">
    <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>
  <body class="diario-body">
    <div class="diario-bg-gradient"></div>
    <div class="app-wrap">
      <div class="brand-bar">
        <div class="brand-left">
          <span>🌿</span>
          <span class="brand-name">Tu Pausa</span>
          <div class="brand-sep"></div>
          <span class="brand-tagline">Tu Esencia</span>
        </div>
        <% if authenticated? %>
          <div class="brand-actions">
            <span class="brand-username">Hola, <%= current_user.name.split(" ").first %></span>
            <%= button_to "Salir", sign_out_path, :method => :delete, class: "btn btn-sm diario-btn-salir" %>
          </div>
        <% end %>
      </div>

      <%= render "shared/diario_flash" %>

      <%= yield %>
    </div>
  </body>
</html>
```

---

## Paso 10: CSS del diario

Agregar al final de `app/assets/tailwind/application.css` (sin modificar nada existente):

```css
/* ===== DIARIO DE CANSANCIO — Tu Pausa, Tu Esencia ===== */
/* Las clases existentes del cuestionario no se modifican  */

/* ─── Variables del diario (scoped bajo .diario-body) ─── */
.diario-body {
  font-family: 'DM Sans', sans-serif;
  background: #f7f4ef;
  color: #2a2a35;
  min-height: 100vh;
  font-size: 15px;
}

/* Gradiente de fondo del diario (posición fija, decorativo) */
.diario-bg-gradient {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background:
    radial-gradient(ellipse at 10% 15%, rgba(200,207,232,0.45) 0%, transparent 50%),
    radial-gradient(ellipse at 88% 82%, rgba(82,183,136,0.13) 0%, transparent 48%);
  pointer-events: none;
  z-index: 0;
}

/* ─── Layout ─── */
.app-wrap {
  position: relative;
  z-index: 1;
  max-width: 700px;
  margin: 0 auto;
  padding: 0 16px 70px;
}

/* ─── Brand bar ─── */
.brand-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 0 12px;
}
.brand-left { display: flex; align-items: center; gap: 10px; }
.brand-name {
  font-family: 'Cormorant Garamond', serif;
  font-size: 15px;
  font-weight: 400;
  letter-spacing: 2px;
  text-transform: uppercase;
  color: #2d6a4f;
}
.brand-sep { width: 1px; height: 14px; background: #b0bae0; }
.brand-tagline { font-size: 11px; color: #9ca3af; letter-spacing: 1px; font-style: italic; }
.brand-actions { display: flex; gap: 8px; align-items: center; }
.brand-username { font-size: 12px; color: #6b7280; }
.diario-btn-salir {
  background: transparent !important;
  border: 1.5px solid #ede8e0 !important;
  color: #6b7280 !important;
  border-radius: 20px !important;
  padding: 6px 14px !important;
  font-size: 12px !important;
  cursor: pointer !important;
}

/* ─── Main header ─── */
.diario-main-header { text-align: center; padding: 10px 0 24px; }
.diario-main-header h1 {
  font-family: 'Cormorant Garamond', serif;
  font-size: clamp(36px, 7vw, 50px);
  font-weight: 300;
  color: #2a2a35;
  line-height: 1.1;
}
.diario-main-header h1 em { color: #2d6a4f; font-style: italic; }
.diario-main-header .sub { font-size: 13px; color: #6b7280; margin-top: 8px; font-weight: 300; }

/* ─── Nav bar (días) ─── */
.nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #ffffff;
  border-radius: 16px;
  padding: 12px 16px;
  margin-bottom: 14px;
  box-shadow: 0 2px 14px rgba(0,0,0,0.05);
}
.nav-days { display: flex; gap: 4px; flex-wrap: wrap; flex: 1; }
.day-dot {
  width: 24px; height: 24px; border-radius: 50%;
  border: 1.5px solid #b0bae0; background: transparent;
  font-size: 9px; font-weight: 600; color: #9ca3af;
  display: flex; align-items: center; justify-content: center;
  transition: all 0.2s; font-family: 'DM Sans', sans-serif;
  text-decoration: none;
}
.day-dot.completed { background: #d8f3dc; border-color: #52b788; color: #2d6a4f; }
.day-dot.active { background: #2d6a4f; border-color: #2d6a4f; color: white; transform: scale(1.18); }
.day-dot.locked { opacity: 0.3; pointer-events: none; }
.nav-actions { display: flex; gap: 8px; margin-left: 12px; flex-shrink: 0; }

/* ─── Progress bar ─── */
.progress-wrap {
  background: #ffffff;
  border-radius: 12px;
  padding: 12px 18px;
  box-shadow: 0 2px 14px rgba(0,0,0,0.05);
  margin-bottom: 14px;
}
.progress-info { display: flex; justify-content: space-between; margin-bottom: 7px; }
.progress-info span { font-size: 12px; color: #6b7280; }
.progress-info strong { font-size: 12px; color: #2d6a4f; }
.progress-track { height: 5px; background: #eaecf6; border-radius: 3px; overflow: hidden; }
.progress-fill { height: 100%; background: #2d6a4f; border-radius: 3px; transition: width 0.6s ease; }

/* ─── Cards ─── */
.diario-card {
  background: #ffffff;
  border-radius: 20px;
  box-shadow: 0 4px 28px rgba(0,0,0,0.07);
  margin-bottom: 14px;
}
.diario-card-body { padding: 28px 30px; }
.diario-card-sm { box-shadow: 0 2px 14px rgba(0,0,0,0.05); }

/* ─── Botones del diario ─── */
.btn {
  display: inline-block;
  border: none;
  border-radius: 50px;
  font-family: 'DM Sans', sans-serif;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  text-decoration: none;
  text-align: center;
}
.btn-primary-diario {
  background: #2d6a4f;
  color: white;
  padding: 13px 36px;
  font-size: 15px;
  border: none;
}
.btn-primary-diario:hover { background: #235c43; transform: translateY(-1px); box-shadow: 0 8px 24px rgba(45,106,79,0.28); }
.btn-secondary-diario {
  background: transparent;
  color: #6b7280;
  border: 1.5px solid #ede8e0;
  padding: 11px 26px;
  font-size: 14px;
}
.btn-secondary-diario:hover { border-color: #b0bae0; color: #2a2a35; }
.btn-sm { padding: 7px 16px; font-size: 12px; }
.btn-icon-diario {
  background: transparent;
  border: 1.5px solid #b0bae0;
  color: #6b7280;
  width: 34px; height: 34px;
  border-radius: 50%;
  padding: 0; font-size: 14px;
  display: flex; align-items: center; justify-content: center;
}
.btn-icon-diario:hover { border-color: #52b788; color: #2d6a4f; background: #d8f3dc; }

/* ─── Formularios del diario ─── */
.diario-field-label {
  font-size: 11px;
  letter-spacing: 1.5px;
  text-transform: uppercase;
  color: #6b7280;
  font-weight: 500;
  margin-bottom: 8px;
  display: block;
}
.diario-field-input,
.diario-field-textarea,
.diario-field-select {
  width: 100%;
  border: 1.5px solid #eaecf6;
  border-radius: 12px;
  padding: 12px 16px;
  font-family: 'DM Sans', sans-serif;
  font-size: 14px;
  color: #2a2a35;
  background: #f7f4ef;
  transition: border-color 0.2s;
  outline: none;
  line-height: 1.6;
}
.diario-field-input:focus,
.diario-field-textarea:focus,
.diario-field-select:focus {
  border-color: #52b788;
  background: #ffffff;
}
.diario-field-textarea { resize: none; min-height: 88px; }
.diario-field-error { font-size: 12px; color: #ef4444; margin-top: 4px; }

/* ─── Ratings ─── */
.ratings-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin: 18px 0;
}
.rating-label {
  font-size: 13px;
  color: #2a2a35;
  font-weight: 500;
  margin-bottom: 8px;
  display: flex;
  align-items: center;
  gap: 6px;
}
.rating-dots { display: flex; gap: 5px; }
.rdot {
  width: 30px; height: 30px;
  border-radius: 50%;
  border: 1.5px solid #b0bae0;
  background: transparent;
  cursor: pointer;
  font-size: 11px; font-weight: 600; color: #6b7280;
  display: flex; align-items: center; justify-content: center;
  transition: all 0.15s;
  font-family: 'DM Sans', sans-serif;
}
.rdot:hover { border-color: #52b788; color: #2d6a4f; background: #d8f3dc; }
.rdot[data-selected="true"][data-level="low"]  { background: #c8cfe8; border-color: #b0bae0; color: #2a2a35; }
.rdot[data-selected="true"][data-level="mid"]  { background: #fbbf24; border-color: #d97706; color: white; }
.rdot[data-selected="true"][data-level="high"] { background: #ef4444; border-color: #dc2626; color: white; }

/* ─── Sleep grid ─── */
.sleep-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin: 18px 0;
}
.sleep-card { background: #eaecf6; border-radius: 14px; padding: 14px; }
.sleep-card label {
  font-size: 11px; letter-spacing: 1.5px; text-transform: uppercase;
  color: #6b7280; font-weight: 500; display: block; margin-bottom: 7px;
}
.sleep-card input,
.sleep-card select {
  width: 100%;
  border: 1.5px solid #c8cfe8;
  border-radius: 8px;
  padding: 8px 11px;
  font-family: 'DM Sans', sans-serif;
  font-size: 14px;
  color: #2a2a35;
  background: #ffffff;
  outline: none;
  transition: border-color 0.2s;
}
.sleep-card input:focus,
.sleep-card select:focus { border-color: #52b788; }
.sleep-span2 { grid-column: span 2; }

/* ─── Day header ─── */
.day-header {
  display: flex; align-items: flex-start; justify-content: space-between;
  padding-bottom: 18px; border-bottom: 1px solid #eaecf6; margin-bottom: 22px;
}
.day-number {
  font-family: 'Cormorant Garamond', serif;
  font-size: 56px; font-weight: 300; line-height: 1;
  color: #b0bae0; min-width: 65px;
}
.day-info { flex: 1; padding: 0 12px; }
.day-info h2 { font-family: 'Cormorant Garamond', serif; font-size: 22px; font-weight: 400; color: #2a2a35; }
.day-badge {
  background: #d8f3dc; color: #2d6a4f;
  font-size: 11px; font-weight: 500;
  padding: 4px 12px; border-radius: 20px; letter-spacing: 0.5px;
  white-space: nowrap; margin-top: 4px;
}

/* ─── Pausa sugerida ─── */
.pausa-sugerida {
  background: linear-gradient(135deg, rgba(200,207,232,0.35), rgba(216,243,220,0.4));
  border-radius: 16px; padding: 16px 20px; margin-bottom: 20px;
  border: 1px solid rgba(176,186,224,0.5);
  display: flex; align-items: flex-start; gap: 12px;
}
.ps-icon { font-size: 24px; flex-shrink: 0; margin-top: 2px; }
.ps-body h4 {
  font-size: 11px; letter-spacing: 1.5px; text-transform: uppercase;
  color: #2d6a4f; font-weight: 600; margin-bottom: 4px;
}
.ps-body p { font-size: 13px; color: #2a2a35; line-height: 1.65; }

/* ─── Tipo chips ─── */
.tipo-chips { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 14px; }
.tipo-chip {
  padding: 7px 14px; border-radius: 20px; font-size: 13px;
  border: 1.5px solid #b0bae0; cursor: pointer;
  color: #6b7280; transition: all 0.2s; background: transparent;
  font-family: 'DM Sans', sans-serif;
}
.tipo-chip.active { background: #d8f3dc; border-color: #2d6a4f; color: #2d6a4f; }

/* ─── Tipo nuevo reveal ─── */
.tipo-reveal {
  background: linear-gradient(135deg, #eaecf6, #d8f3dc);
  border-radius: 14px; padding: 14px 18px; margin-bottom: 18px; font-size: 13px; line-height: 1.6;
}
.tipo-reveal strong { color: #2d6a4f; font-size: 14px; }

/* ─── Section helpers ─── */
.diario-divider { height: 1px; background: #eaecf6; margin: 22px 0; }
.section-title {
  font-family: 'Cormorant Garamond', serif;
  font-size: 19px; font-weight: 400; color: #2a2a35;
  margin-bottom: 12px; font-style: italic;
}

/* ─── Save row ─── */
.save-row {
  display: flex; align-items: center; justify-content: flex-end;
  margin-top: 22px; gap: 10px;
}
.save-msg { font-size: 13px; color: #2d6a4f; font-style: italic; margin-right: auto; }

/* ─── Start banner ─── */
.start-banner {
  background: #2d6a4f; border-radius: 20px; padding: 22px 28px;
  margin-bottom: 14px; display: flex; align-items: center; gap: 16px;
  box-shadow: 0 8px 28px rgba(45,106,79,0.25);
}
.start-banner-icon { font-size: 36px; flex-shrink: 0; }
.start-banner-text { flex: 1; }
.start-banner-eyebrow {
  font-size: 11px; letter-spacing: 2px; text-transform: uppercase;
  color: rgba(255,255,255,0.7); font-weight: 500; margin-bottom: 4px;
}
.start-banner-title {
  font-family: 'Cormorant Garamond', serif;
  font-size: 20px; color: white; font-weight: 400; line-height: 1.3;
}
.start-banner-sub { font-size: 13px; color: rgba(255,255,255,0.8); margin-top: 4px; }

/* ─── Summary ─── */
.summary-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin: 18px 0; }
.stat-card {
  background: #ffffff; border-radius: 18px; padding: 20px;
  box-shadow: 0 2px 14px rgba(0,0,0,0.05); text-align: center;
}
.sc-icon { font-size: 28px; margin-bottom: 8px; }
.sc-value {
  font-family: 'Cormorant Garamond', serif;
  font-size: 30px; font-weight: 400; color: #2d6a4f; line-height: 1;
}
.sc-label { font-size: 11px; color: #6b7280; margin-top: 4px; }

.tipo-bars-card {
  background: #ffffff; border-radius: 18px; padding: 24px;
  box-shadow: 0 2px 14px rgba(0,0,0,0.05); margin-bottom: 12px;
}
.tipo-bars-card h3 {
  font-family: 'Cormorant Garamond', serif;
  font-size: 20px; font-weight: 400; margin-bottom: 18px; color: #2a2a35;
}
.tbr { margin-bottom: 13px; }
.tbr-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 5px; }
.tbr-name { font-size: 13px; font-weight: 500; color: #2a2a35; display: flex; align-items: center; gap: 6px; }
.tbr-val { font-size: 12px; color: #6b7280; }
.tbr-track { height: 8px; background: #eaecf6; border-radius: 4px; overflow: hidden; }
.tbr-fill { height: 100%; border-radius: 4px; transition: width 1s ease; background: #2d6a4f; }
.tbr-fill.mid { background: #fbbf24; }
.tbr-fill.high { background: #ef4444; }

.pausa-estrella-card {
  background: linear-gradient(135deg, #2d6a4f, #52b788);
  color: white; border-radius: 20px; padding: 26px;
  margin-bottom: 12px; text-align: center;
}
.pausa-estrella-card h3 {
  font-family: 'Cormorant Garamond', serif;
  font-size: 22px; font-weight: 300; font-style: italic; margin-bottom: 10px;
}
.ps-quote { font-size: 16px; font-weight: 500; line-height: 1.5; }
.ps-empty { font-size: 13px; opacity: 0.75; }

.complete-banner {
  background: #d8f3dc; border: 1.5px solid #52b788;
  border-radius: 14px; padding: 14px 20px;
  text-align: center; font-size: 14px; color: #2d6a4f;
  font-weight: 500; margin-bottom: 16px;
}

/* ─── Auth ─── */
.auth-wrap { max-width: 420px; margin: 0 auto; padding: 40px 16px; }
.auth-card {
  background: #ffffff; border-radius: 24px; padding: 40px;
  box-shadow: 0 4px 28px rgba(0,0,0,0.07);
}
.auth-card h2 {
  font-family: 'Cormorant Garamond', serif;
  font-size: 28px; font-weight: 400; color: #2a2a35; margin-bottom: 6px;
}
.auth-card .auth-sub { font-size: 13px; color: #6b7280; margin-bottom: 28px; }
.auth-field { margin-bottom: 16px; }
.auth-footer { text-align: center; margin-top: 20px; font-size: 13px; color: #6b7280; }
.auth-footer a { color: #2d6a4f; text-decoration: none; font-weight: 500; }
.auth-footer a:hover { text-decoration: underline; }

/* ─── Flash messages del diario ─── */
.diario-flash { border-radius: 12px; padding: 12px 18px; margin-bottom: 14px; font-size: 13px; }
.diario-flash-notice { background: #d8f3dc; color: #2d6a4f; border: 1px solid #52b788; }
.diario-flash-alert  { background: #fee2e2; color: #dc2626; border: 1px solid #fca5a5; }

/* ─── Responsive ─── */
@media (max-width: 480px) {
  .diario-card-body { padding: 20px 18px; }
  .ratings-grid,
  .sleep-grid,
  .summary-grid { grid-template-columns: 1fr; }
  .rdot { width: 27px; height: 27px; font-size: 11px; }
  .sleep-span2 { grid-column: span 1; }
  .start-banner { flex-direction: column; text-align: center; }
  .auth-card { padding: 28px 20px; }
}
```

---

## Paso 11: Vistas del diario

### `app/views/shared/_diario_flash.html.erb`

```erb
<% flash.each do |type, message| %>
  <div class="diario-flash <%= type == "notice" ? "diario-flash-notice" : "diario-flash-alert" %>">
    <%= message %>
  </div>
<% end %>
```

### `app/views/shared/_nav.html.erb`

```erb
<%# Locals: completed_days (array de ints), current_day (int) %>
<div class="nav-bar">
  <div class="nav-days">
    <% (1..15).each do |d| %>
      <%
        done       = completed_days.include?(d)
        is_current = d == current_day
        accessible = d <= current_day || done
        css  = "day-dot"
        css += " completed" if done && !is_current
        css += " active"    if is_current
        css += " locked"    unless accessible || done
      %>
      <% if accessible || done %>
        <%= link_to d, diary_day_path(d), class: css %>
      <% else %>
        <span class="<%= css %>"><%= d %></span>
      <% end %>
    <% end %>
  </div>
  <div class="nav-actions">
    <%= link_to "Resumen", summary_path, class: "btn btn-sm",
          style: "background:#eaecf6;color:#2a2a35;border-radius:20px;font-weight:500;font-family:'DM Sans',sans-serif" %>
  </div>
</div>

<%
  done_count = completed_days.length
  pct = (done_count.to_f / 15 * 100).round
%>
<div class="progress-wrap">
  <div class="progress-info">
    <span>Tu progreso</span>
    <strong><%= done_count %> / 15 días</strong>
  </div>
  <div class="progress-track">
    <div class="progress-fill" style="width:<%= pct %>%"></div>
  </div>
</div>
```

### `app/views/sessions/new.html.erb`

Reemplazar completamente la vista generada por Rails:

```erb
<% content_for :title, "Iniciar sesión · Diario de Cansancio" %>

<div class="diario-main-header">
  <h1>Diario de <em>cansancio</em></h1>
  <div class="sub">Micro-pausas que alivian · 15 días de autoconocimiento</div>
</div>

<div class="auth-wrap">
  <div class="auth-card">
    <h2>Bienvenida de vuelta</h2>
    <p class="auth-sub">Tu diario te está esperando</p>

    <%= form_with url: sign_in_path do |f| %>
      <div class="auth-field">
        <%= f.label :email_address, "Email", class: "diario-field-label" %>
        <%= f.email_field :email_address, class: "diario-field-input",
              placeholder: "tu@email.com", autocomplete: "email" %>
      </div>

      <div class="auth-field">
        <%= f.label :password, "Contraseña", class: "diario-field-label" %>
        <%= f.password_field :password, class: "diario-field-input",
              placeholder: "Tu contraseña", autocomplete: "current-password" %>
      </div>

      <div style="display:flex;align-items:center;margin:16px 0 24px">
        <label style="display:flex;align-items:center;gap:8px;font-size:13px;color:#6b7280;cursor:pointer">
          <%= f.check_box :remember_me, style: "accent-color:#2d6a4f" %>
          Recordarme
        </label>
      </div>

      <%= f.submit "Ingresar →", class: "btn btn-primary-diario", style: "width:100%" %>
    <% end %>

    <div class="auth-footer">
      ¿No tenés cuenta? <%= link_to "Registrate", sign_up_path %>
    </div>
  </div>
</div>
```

### `app/views/registrations/new.html.erb`

```erb
<% content_for :title, "Crear cuenta · Diario de Cansancio" %>

<div class="diario-main-header">
  <h1>Diario de <em>cansancio</em></h1>
  <div class="sub">Micro-pausas que alivian · 15 días de autoconocimiento</div>
</div>

<div class="auth-wrap">
  <div class="auth-card">
    <h2>Crear tu cuenta</h2>
    <p class="auth-sub">Empezá tu diario de 15 días de forma gratuita</p>

    <%= form_with model: @user, url: sign_up_path do |f| %>
      <div class="auth-field">
        <%= f.label :name, "Tu nombre", class: "diario-field-label" %>
        <%= f.text_field :name, class: "diario-field-input", placeholder: "¿Cómo te llamás?" %>
        <% if @user.errors[:name].any? %>
          <div class="diario-field-error"><%= @user.errors[:name].first %></div>
        <% end %>
      </div>

      <div class="auth-field">
        <%= f.label :email_address, "Email", class: "diario-field-label" %>
        <%= f.email_field :email_address, class: "diario-field-input", placeholder: "tu@email.com" %>
        <% if @user.errors[:email_address].any? %>
          <div class="diario-field-error"><%= @user.errors[:email_address].first %></div>
        <% end %>
      </div>

      <div class="auth-field">
        <%= f.label :password, "Contraseña", class: "diario-field-label" %>
        <%= f.password_field :password, class: "diario-field-input", placeholder: "Mínimo 12 caracteres" %>
        <% if @user.errors[:password].any? %>
          <div class="diario-field-error"><%= @user.errors[:password].first %></div>
        <% end %>
      </div>

      <div class="auth-field">
        <%= f.label :password_confirmation, "Confirmá tu contraseña", class: "diario-field-label" %>
        <%= f.password_field :password_confirmation, class: "diario-field-input", placeholder: "Repetí tu contraseña" %>
      </div>

      <div style="margin-top:24px">
        <%= f.submit "Crear mi cuenta →", class: "btn btn-primary-diario", style: "width:100%" %>
      </div>
    <% end %>

    <div class="auth-footer">
      ¿Ya tenés cuenta? <%= link_to "Iniciá sesión", sign_in_path %>
    </div>
  </div>
</div>
```

### `app/views/diary_entries/show.html.erb`

```erb
<% content_for :title, "Día #{@day} · Diario de Cansancio" %>

<%= render "shared/nav", completed_days: @completed_days, current_day: @day %>

<div class="diario-main-header" style="padding-bottom:16px">
  <h1>Diario de <em>cansancio</em></h1>
</div>

<div class="diario-card" data-controller="diary"
     data-diary-day-value="<%= @day %>"
     data-diary-update-rating-url-value="<%= update_rating_diary_day_path(@day) %>">

  <%= form_with url: save_diary_day_path(@day), method: :post, local: true do |f| %>
    <div class="diario-card-body">

      <!-- DAY HEADER -->
      <div class="day-header">
        <div class="day-number"><%= @day.to_s.rjust(2, "0") %></div>
        <div class="day-info">
          <h2>
            <% if @day == 15 %>
              Día 15 · Creación de hábitos
            <% else %>
              Día <%= @day %>
            <% end %>
          </h2>
          <%= f.date_field :fecha, value: @entry.fecha,
                style: "border:none;background:transparent;font-size:12px;color:#6b7280;font-family:'DM Sans',sans-serif;outline:none;margin-top:5px;padding:0" %>
        </div>
        <div class="day-badge">
          <%= @entry.tipos_disponibles.length %> tipo<%= @entry.tipos_disponibles.length > 1 ? "s" : "" %>
        </div>
      </div>

      <!-- TIPO NUEVO REVEAL -->
      <% if @entry.tipo_nuevo %>
        <% tn = DiaryEntry::TIPO_LABELS[@entry.tipo_nuevo] %>
        <div class="tipo-reveal">
          ✨ <strong>Hoy incorporamos el cansancio <%= tn[:label] %> <%= tn[:icon] %></strong><br>
          <span style="color:#6b7280;font-size:13px"><%= tn[:desc] %></span>
        </div>
      <% end %>

      <!-- MICRO-PAUSA SUGERIDA -->
      <% pausa = @entry.pausa_sugerida %>
      <div class="pausa-sugerida">
        <div class="ps-icon"><%= pausa[:icon] %></div>
        <div class="ps-body">
          <h4>Micro-pausa sugerida del día</h4>
          <p><%= pausa[:text] %></p>
        </div>
      </div>

      <!-- PALABRA CENTRAL -->
      <label class="diario-field-label">Palabra central / síntoma</label>
      <%= f.text_field :palabra, value: @entry.palabra,
            class: "diario-field-input",
            placeholder: "¿Cómo te sentís hoy en una palabra?" %>

      <div class="diario-divider"></div>

      <!-- RATINGS -->
      <div class="ratings-grid">
        <% @entry.tipos_disponibles.each do |tipo| %>
          <% info = DiaryEntry::TIPO_LABELS[tipo] %>
          <div class="rating-block">
            <div class="rating-label">
              <span><%= info[:icon] %></span>
              <%= info[:label] %>
            </div>
            <div class="rating-dots">
              <% (1..5).each do |n| %>
                <%
                  current_val = @entry.rating_for(tipo)
                  level = n <= 2 ? "low" : n == 3 ? "mid" : "high"
                  selected = current_val == n
                %>
                <div class="rdot"
                     data-selected="<%= selected %>"
                     data-level="<%= selected ? level : "" %>"
                     data-action="click->diary#setRating"
                     data-diary-tipo-param="<%= tipo %>"
                     data-diary-valor-param="<%= n %>">
                  <%= n %>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>

      <!-- TIPO MÁS ALTO (días impares con múltiples tipos, no día 15) -->
      <% if @entry.tipos_disponibles.length > 1 && !@entry.reflexion_day? && @day != 15 %>
        <div class="diario-divider"></div>
        <label class="diario-field-label">Tipo más alto hoy</label>
        <div class="tipo-chips" data-controller="chips">
          <% @entry.tipos_disponibles.each do |tipo| %>
            <% info = DiaryEntry::TIPO_LABELS[tipo] %>
            <div class="tipo-chip <%= @entry.tipo_alto == tipo ? "active" : "" %>"
                 data-action="click->chips#select">
              <%= info[:icon] %> <%= info[:label] %>
              <input type="radio" name="diary_entry[tipo_alto]" value="<%= tipo %>"
                     <%= @entry.tipo_alto == tipo ? "checked" : "" %>
                     style="display:none">
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- SUEÑO -->
      <div class="diario-divider"></div>
      <p class="section-title">Registro de sueño</p>
      <div class="sleep-grid">
        <div class="sleep-card">
          <label>Hora de dormir</label>
          <%= f.time_field :hora_dormir, value: @entry.hora_dormir %>
        </div>
        <div class="sleep-card">
          <label>Horas dormidas</label>
          <%= f.number_field :horas_dormidas, value: @entry.horas_dormidas,
                min: 0, max: 24, step: 0.5, placeholder: "7.5" %>
        </div>
        <div class="sleep-card sleep-span2">
          <label>Calidad del sueño</label>
          <%= f.select :calidad_sueno,
                [["", ""], ["😌 Muy buena", "Muy buena"], ["🙂 Buena", "Buena"],
                 ["😐 Regular", "Regular"], ["😔 Mala", "Mala"], ["😩 Muy mala", "Muy mala"]],
                { :selected => @entry.calidad_sueno } %>
        </div>
      </div>

      <!-- CAMPO PRINCIPAL: SENSACIÓN o REFLEXIÓN -->
      <div class="diario-divider"></div>
      <% if @entry.reflexion_day? %>
        <p class="section-title">Reflexión del día</p>
        <%= f.text_area :reflexion, value: @entry.reflexion,
              class: "diario-field-textarea",
              placeholder: "¿Qué observaste hoy en vos misma?" %>
      <% else %>
        <p class="section-title">Sensación de la práctica de hoy</p>
        <%= f.text_area :sensacion, value: @entry.sensacion,
              class: "diario-field-textarea",
              placeholder: "¿Cómo te sentiste con la práctica de hoy?" %>
      <% end %>

      <!-- MICRO-PAUSA REGISTRADA -->
      <% if @entry.micropausa_day? %>
        <div class="diario-divider"></div>
        <p class="section-title">Micro-pausa que probé</p>
        <%= f.text_area :micropausa, value: @entry.micropausa,
              class: "diario-field-textarea",
              placeholder: "¿Probaste la sugerencia de hoy? ¿Cómo te fue?" %>
      <% end %>

      <!-- DÍA 15: CAMPOS ESPECIALES -->
      <% if @day == 15 %>
        <div class="diario-divider"></div>
        <p class="section-title">Reflexión final</p>
        <%= f.text_area :reflexion_final, value: @entry.reflexion_final,
              class: "diario-field-textarea",
              placeholder: "¿Qué aprendiste sobre tu cansancio en estos 15 días?",
              rows: 4 %>

        <div style="height:14px"></div>
        <label class="diario-field-label">Mi micro-pausa estrella</label>
        <%= f.text_field :pausa_estrella, value: @entry.pausa_estrella,
              class: "diario-field-input",
              placeholder: "¿Cuál micro-pausa fue más efectiva para vos?" %>

        <div style="height:14px"></div>
        <label class="diario-field-label">Próximo foco</label>
        <%= f.text_field :proximo_foco, value: @entry.proximo_foco,
              class: "diario-field-input",
              placeholder: "¿En qué tipo de descanso querés enfocarte?" %>

        <div style="height:14px"></div>
        <label class="diario-field-label">Rutina posible</label>
        <%= f.text_area :rutina, value: @entry.rutina,
              class: "diario-field-textarea",
              placeholder: "¿Qué rutina de micro-pausas podrías sostener?" %>
      <% end %>

      <!-- SAVE ROW -->
      <div class="save-row">
        <% if @day < 15 %>
          <%= f.submit "Guardar y continuar →", class: "btn btn-secondary-diario",
                name: "commit", value: "save_and_next" %>
        <% end %>
        <%= f.submit @day == 15 ? "Guardar día final ✨" : "Guardar",
              class: "btn btn-primary-diario" %>
      </div>

    </div>
  <% end %>
</div>
```

### `app/views/summaries/show.html.erb`

```erb
<% content_for :title, "Resumen · Diario de Cansancio" %>

<%= render "shared/nav", completed_days: @completed_days, current_day: current_user.next_pending_day %>

<div class="diario-main-header" style="padding-bottom:16px">
  <h1>Observación del <em>proceso</em></h1>
  <div class="sub">Lo que descubriste en estos días</div>
</div>

<% if @completed_days.length == 15 %>
  <div class="complete-banner">
    🎉 ¡Completaste los 15 días! Este registro es un regalo para vos misma.
  </div>
<% end %>

<div class="summary-grid">
  <div class="stat-card">
    <div class="sc-icon">📅</div>
    <div class="sc-value"><%= @completed_days.length %></div>
    <div class="sc-label">días completados</div>
  </div>
  <div class="stat-card">
    <div class="sc-icon">😴</div>
    <div class="sc-value"><%= @sleep_avg ? "#{@sleep_avg}h" : "–" %></div>
    <div class="sc-label">promedio de sueño</div>
  </div>
</div>

<div class="tipo-bars-card">
  <h3>Tus niveles de cansancio</h3>
  <% if @fatigue_avgs.empty? %>
    <p style="color:#6b7280;font-size:13px;text-align:center">
      Completá algunos días para ver tus patrones aquí.
    </p>
  <% else %>
    <% @sorted_tipos.each do |tipo| %>
      <% avg = @fatigue_avgs[tipo] || 0 %>
      <% next if avg == 0 %>
      <% info = DiaryEntry::TIPO_LABELS[tipo] %>
      <% pct = (avg / 5.0 * 100).round %>
      <% fill_cls = avg >= 4 ? "high" : avg >= 3 ? "mid" : "" %>
      <div class="tbr">
        <div class="tbr-top">
          <div class="tbr-name"><%= info[:icon] %> <%= info[:label] %></div>
          <div class="tbr-val"><%= avg %> / 5</div>
        </div>
        <div class="tbr-track">
          <div class="tbr-fill <%= fill_cls %>" style="width:<%= pct %>%"></div>
        </div>
      </div>
    <% end %>
  <% end %>
</div>

<% if @top_tipo && @fatigue_avgs[@top_tipo].to_f > 0 %>
  <% top_info = DiaryEntry::TIPO_LABELS[@top_tipo] %>
  <div style="background:#eaecf6;border-radius:14px;padding:16px 20px;margin-bottom:12px">
    <strong style="color:#2d6a4f;font-size:15px">
      <%= top_info[:icon] %> Tipo predominante: <%= top_info[:label] %>
    </strong><br>
    <span style="font-size:13px;color:#6b7280"><%= top_info[:desc] %></span>
  </div>
<% end %>

<div class="pausa-estrella-card">
  <h3>Mi micro-pausa estrella ✨</h3>
  <% if @pausa_estrella.present? %>
    <div class="ps-quote">"<%= @pausa_estrella %>"</div>
  <% else %>
    <div class="ps-empty">
      Completá el día 15 para revelar tu micro-pausa estrella
    </div>
  <% end %>
</div>

<% if @day15&.proximo_foco.present? %>
  <div class="diario-card diario-card-sm" style="text-align:center;margin-bottom:12px">
    <div class="diario-card-body">
      <p class="section-title" style="margin-bottom:6px">Próximo foco</p>
      <p style="font-size:16px;color:#2a2a35"><%= @day15.proximo_foco %></p>
    </div>
  </div>
<% end %>

<% if @day15&.rutina.present? %>
  <div class="diario-card diario-card-sm" style="margin-bottom:12px">
    <div class="diario-card-body">
      <p class="section-title" style="margin-bottom:8px">Rutina posible</p>
      <p style="font-size:14px;color:#6b7280;line-height:1.7"><%= @day15.rutina %></p>
    </div>
  </div>
<% end %>

<div style="text-align:center;margin-top:24px">
  <%= link_to "← Volver al diario", diary_day_path(current_user.next_pending_day), class: "btn btn-secondary-diario" %>
</div>
```

---

## Paso 12: Stimulus controllers

### `app/javascript/controllers/diary_controller.js`

```javascript
// app/javascript/controllers/diary_controller.js
// Maneja actualizaciones de ratings via fetch AJAX.
// EXCEPCIÓN justificada al Hotwire-first guideline: los ratings se guardan
// instantáneamente al hacer click, lo que requiere PATCH al servidor sin submit.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    day: Number,
    updateRatingUrl: String
  }

  async setRating(event) {
    const tipo  = event.params.tipo
    const valor = parseInt(event.params.valor)

    this.updateRatingUI(tipo, valor)

    try {
      const response = await fetch(this.updateRatingUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({ tipo, valor })
      })

      if (!response.ok) {
        console.error("Error guardando rating")
      }
    } catch (e) {
      console.error("Error de red:", e)
    }
  }

  updateRatingUI(tipo, valor) {
    const allDots = this.element.querySelectorAll(`[data-diary-tipo-param="${tipo}"]`)

    allDots.forEach(dot => {
      const dotValor = parseInt(dot.dataset.diaryValorParam)
      const level    = dotValor <= 2 ? "low" : dotValor === 3 ? "mid" : "high"

      if (dotValor === valor) {
        dot.dataset.selected = "true"
        dot.dataset.level    = level
      } else {
        dot.dataset.selected = "false"
        delete dot.dataset.level
      }
    })
  }
}
```

### `app/javascript/controllers/chips_controller.js`

```javascript
// app/javascript/controllers/chips_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  select(event) {
    const clicked = event.currentTarget

    this.element.querySelectorAll(".tipo-chip").forEach(chip => {
      chip.classList.remove("active")
      const radio = chip.querySelector("input[type='radio']")
      if (radio) radio.checked = false
    })

    clicked.classList.add("active")
    const radio = clicked.querySelector("input[type='radio']")
    if (radio) radio.checked = true
  }
}
```

---

## Paso 13: Modificar `SessionsController` generado

```ruby
# app/controllers/sessions_controller.rb
# frozen_string_literal: true

class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create,
             :with => -> { redirect_to new_session_url, alert: "Demasiados intentos. Esperá unos minutos." }

  layout "diario"

  def new; end

  def create
    if (user = User.authenticate_by(params.permit(:email_address, :password)))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Email o contraseña incorrectos."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
```

---

## Resumen de archivos

### Archivos NUEVOS a crear:
- `db/migrate/TIMESTAMP_add_name_to_users.rb`
- `db/migrate/TIMESTAMP_create_diary_entries.rb`
- `app/models/diary_entry.rb`
- `app/controllers/diary_entries_controller.rb`
- `app/controllers/registrations_controller.rb`
- `app/controllers/summaries_controller.rb`
- `app/views/layouts/diario.html.erb`
- `app/views/diary_entries/show.html.erb`
- `app/views/summaries/show.html.erb`
- `app/views/sessions/new.html.erb` (reemplaza el generado)
- `app/views/registrations/new.html.erb`
- `app/views/shared/_nav.html.erb`
- `app/views/shared/_diario_flash.html.erb`
- `app/javascript/controllers/diary_controller.js`
- `app/javascript/controllers/chips_controller.js`

### Archivos a MODIFICAR (sin romper lo existente):
- `app/models/user.rb` — agregar relaciones y métodos del diario
- `app/controllers/application_controller.rb` — incluir `Authentication`
- `app/controllers/sessions_controller.rb` — agregar `layout "diario"` (generado por Rails)
- `config/routes.rb` — agregar rutas del diario
- `app/assets/tailwind/application.css` — agregar sección CSS del diario al final

### Archivos a NO tocar:
- Todo en `app/views/cuestionario/`
- `app/views/layouts/application.html.erb`
- `app/views/shared/_developer_tools.html.erb`
- `app/controllers/cuestionario_controller.rb`
- `app/models/category.rb` y `question.rb`
- Migraciones existentes

---

## Comandos a ejecutar en orden

```bash
# 1. Generar autenticación de Rails 8
bin/rails generate authentication

# 2. Crear migraciones
bin/rails generate migration AddNameToUsers name:string
bin/rails generate migration CreateDiaryEntries

# 3. Editar la migración CreateDiaryEntries ANTES de correr db:migrate
#    (agregar todos los campos según Paso 3)

# 4. Correr migraciones
bin/rails db:migrate

# 5. Compilar Tailwind
bin/rails tailwindcss:build

# 6. Iniciar servidor
bin/rails server -b 0.0.0.0
```

---

## Notas finales importantes

1. **Ratings no van en el form:** Se guardan via AJAX (Stimulus `diary_controller`) directamente al campo JSON `ratings`. El formulario principal guarda el resto.

2. **Coexistencia de layouts:** El cuestionario usa `layouts/application.html.erb`. El diario usa `layouts/diario.html.erb`. Los CSS no se pisan porque usan prefijos distintos (`diario-*`).

3. **`ApplicationController` sin auth global:** El cuestionario (`/cuestionario`) debe seguir siendo público. `require_authentication` solo se pone en los controladores del diario.

4. **Hash rockets:** Seguir el estilo del proyecto: `{ :key => value }` en Ruby, no `{ key: value }`.

5. **Frozen strings:** Todos los archivos Ruby empiezan con `# frozen_string_literal: true`.

6. **Bug corregido:** El método `fatigue_averages` del prompt original tenía `counts[sum]` — ya está corregido a `counts[tipo]` en este documento.

7. **`btn` class conflict:** La clase `.btn` ya existe en el cuestionario con diferentes estilos. En el diario usamos `.btn-primary-diario` y `.btn-secondary-diario` para evitar conflictos. La clase base `.btn` se comparte (misma definición de display/border-radius/transition).

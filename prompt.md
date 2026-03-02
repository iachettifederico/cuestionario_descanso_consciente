# Prompt para OpenCode: Diario de Cansancio — Rails 8

## Objetivo
Construir una aplicación web en Rails 8.0 llamada **"Diario de Cansancio"** para la marca "Tu Pausa, Tu Esencia". Es una app de autoregistro de 15 días donde profesionales de la salud registran sus niveles de cansancio diarios y prueban micro-pausas.

---

## Stack técnico
- **Rails 8.0.2.1**
- **SQLite3**
- **Autenticación built-in de Rails 8** (rails generate authentication, NO Devise)
- **Turbo + Stimulus** vía Importmap (sin Node/webpack)
- Sin gems adicionales

---

## Setup inicial

```bash
rails new diario_cansancio --database=sqlite3
cd diario_cansancio
rails generate authentication
```

---

## Modelos

### User
Generado por `rails generate authentication`. Agregarle:
- `name:string` (migración adicional)
- `has_many :diary_entries, dependent: :destroy`
- Validaciones: `email_address` presence + uniqueness + formato email, `name` presence
- `normalizes :email_address, with: -> e { e.strip.downcase }`

**Métodos del modelo User:**
```ruby
def entry_for(day)
  diary_entries.find_by(day_number: day)
end

def completed_days
  diary_entries.where(saved: true).count
end

def next_pending_day
  completed = diary_entries.where(saved: true).pluck(:day_number)
  (1..15).find { |d| !completed.include?(d) } || 15
end

def fatigue_averages
  # Itera sobre todas las entries, parsea el JSON de ratings,
  # devuelve hash { "fisico" => 3.2, "mental" => 4.1, ... }
  entries = diary_entries.where.not(ratings: [nil, "{}"])
  sums, counts = Hash.new(0), Hash.new(0)
  entries.each do |entry|
    ratings = JSON.parse(entry.ratings) rescue {}
    ratings.each { |tipo, val| next unless val.to_i > 0; sums[tipo] += val.to_i; counts[tipo] += 1 }
  end
  sums.transform_values { |sum| (sum.to_f / counts[sum]).round(1) }
  # OJO: usar counts[tipo], no counts[sum]
end

def sleep_average
  entries = diary_entries.where.not(horas_dormidas: nil)
  return nil if entries.empty?
  (entries.sum(:horas_dormidas) / entries.count).round(1)
end
```

### DiaryEntry
**Migración:**
```ruby
create_table :diary_entries do |t|
  t.references :user, null: false, foreign_key: true
  t.integer  :day_number,     null: false
  t.date     :fecha
  t.string   :palabra
  t.text     :ratings,        default: "{}"   # JSON con los ratings
  t.string   :hora_dormir
  t.decimal  :horas_dormidas, precision: 4, scale: 1
  t.string   :calidad_sueno
  t.string   :tipo_alto
  t.text     :sensacion
  t.text     :reflexion
  t.text     :micropausa
  t.text     :reflexion_final   # solo día 15
  t.string   :pausa_estrella    # solo día 15
  t.string   :proximo_foco      # solo día 15
  t.text     :rutina            # solo día 15
  t.boolean  :saved,           default: false
  t.timestamps
end
add_index :diary_entries, [:user_id, :day_number], unique: true
```

**Constantes del modelo DiaryEntry:**

```ruby
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
  "fisico"     => { label: "Físico",     icon: "💪", desc: "Tu cuerpo necesita movimiento y descanso físico real" },
  "mental"     => { label: "Mental",     icon: "🧠", desc: "Tu mente necesita silencio, límites de información y claridad" },
  "emocional"  => { label: "Emocional",  icon: "💚", desc: "Tu corazón necesita espacio para sentir sin performar" },
  "sensorial"  => { label: "Sensorial",  icon: "👁️",  desc: "Tus sentidos necesitan menos estímulos, menos pantallas" },
  "social"     => { label: "Social",     icon: "🤝", desc: "Tu energía social necesita recarga en soledad o conexión genuina" },
  "creativo"   => { label: "Creativo",   icon: "🎨", desc: "Tu creatividad necesita inspiración o permiso para no producir" },
  "espiritual" => { label: "Espiritual", icon: "🌿", desc: "Tu sentido de propósito necesita reconexión con lo que importa" }
}.freeze

PAUSAS_SUGERIDAS = {
  1  => { icon: "🌬️", text: "Respiración 4-7-8: inhalá 4 segundos, retené 7, exhalá 8. Repetí 3 veces. Ideal antes de tu próximo paciente." },
  2  => { icon: "🚶‍♀️", text: "Caminata de 5 minutos sin teléfono ni destino concreto. Solo mover el cuerpo y observar lo que hay alrededor." },
  3  => { icon: "📋", text: "Vaciado mental: anotá durante 3 minutos todo lo que tenés 'abierto' en la mente, sin ordenar. Solo sacar." },
  4  => { icon: "🧩", text: "Cierre de pestañas mentales: elegí una tarea inconclusa y definí cuándo la vas a retomar. Liberá ese espacio." },
  5  => { icon: "🫁", text: "Pausa de check-in emocional: poné una mano en el pecho, cerrá los ojos y preguntate '¿qué emoción está presente ahora?' Sin juzgar." },
  6  => { icon: "📓", text: "3 líneas de descarga emocional: escribí lo que sentís sin corregir, sin releer. Solo sacarlo afuera." },
  7  => { icon: "🎵", text: "2 minutos de silencio intencional: apagá pantallas y notificaciones. Simplemente escuchá los sonidos del entorno." },
  8  => { icon: "👀", text: "Descanso ocular: cerrá los ojos por 2 minutos con las palmas sobre ellos. Sentí el calor. Nada más." },
  9  => { icon: "🏡", text: "Momento de cierre social: antes de llegar a casa, tomá 5 minutos sola en el auto. Sin hablar con nadie." },
  10 => { icon: "☕", text: "Pausa sin pantalla: tomá un café o té y no revises el teléfono mientras lo hacés. Solo vos y la bebida." },
  11 => { icon: "🎨", text: "Garabato libre: tomá una hoja y un lápiz y dibujá sin objetivo durante 3 minutos. No tiene que significar nada." },
  12 => { icon: "🌿", text: "Salida a la naturaleza express: 5 minutos afuera, mirá algo verde o el cielo. Sin auriculares, sin pantallas." },
  13 => { icon: "🙏", text: "Momento de gratitud silenciosa: cerrá los ojos y nombrá mentalmente 3 cosas pequeñas de hoy que te hicieron bien." },
  14 => { icon: "✍️", text: "Una línea de propósito: escribí en una oración por qué hacés lo que hacés. Solo para recordártelo vos misma." },
  15 => { icon: "🌸", text: "Hoy la micro-pausa es esta misma reflexión. Tomarte este tiempo ya es un acto de descanso consciente." }
}.freeze

REFLEXION_DAYS  = [2, 4, 6, 8, 10].freeze   # días con campo "reflexión"
MICROPAUSA_DAYS = [1, 3, 5, 7, 9, 11, 12, 13, 14].freeze  # días con campo micro-pausa
```

**Métodos del modelo DiaryEntry:**
```ruby
def tipos_disponibles
  TIPOS_POR_DIA[day_number] || []
end

def ratings_hash
  JSON.parse(ratings.presence || "{}") rescue {}
end

def rating_for(tipo)
  ratings_hash[tipo.to_s].to_i
end

def update_rating(tipo, valor)
  current = ratings_hash
  current[tipo.to_s] = valor.to_i
  update(ratings: current.to_json)
end

def tipo_nuevo
  # Retorna el tipo nuevo que se incorpora en días 3,5,7,9,11,13
  return nil unless [3, 5, 7, 9, 11, 13].include?(day_number)
  tipos_disponibles.last
end

def reflexion_day?  = REFLEXION_DAYS.include?(day_number)
def micropausa_day? = MICROPAUSA_DAYS.include?(day_number)
def last_day?       = day_number == 15
def pausa_sugerida  = PAUSAS_SUGERIDAS[day_number]
```

---

## Rutas

```ruby
Rails.application.routes.draw do
  get    "sign_in",  to: "sessions#new",      as: :sign_in
  post   "sign_in",  to: "sessions#create"
  delete "sign_out", to: "sessions#destroy",  as: :sign_out
  get    "sign_up",  to: "registrations#new", as: :sign_up
  post   "sign_up",  to: "registrations#create"

  get   "diario",              to: "diary_entries#index",         as: :diary
  get   "diario/resumen",      to: "summaries#show",              as: :summary
  get   "diario/:day",         to: "diary_entries#show",          as: :diary_day,   constraints: { day: /([1-9]|1[0-5])/ }
  post  "diario/:day",         to: "diary_entries#save",          as: :save_diary_day
  patch "diario/:day/rating",  to: "diary_entries#update_rating", as: :update_rating

  root "diary_entries#index"
end
```

---

## Controllers

### ApplicationController
```ruby
class ApplicationController < ActionController::Base
  include Authentication
  before_action :require_authentication

  def current_user = Current.user
  helper_method :current_user
end
```

### RegistrationsController
- `allow_unauthenticated_access only: [:new, :create]`
- En `create`: `User.new(params)` → si válido, `start_new_session_for(@user)` → redirect a `diary_path`

### DiaryEntriesController
- `index`: redirect a `diary_day_path(current_user.next_pending_day)`
- `show`: setea `@entry` (find_by o build), `@completed_days`
- `save`: `@entry.update(entry_params.merge(saved: true))`. Si `params[:commit] == "save_and_next"` y día < 15 → redirect al día siguiente. Si día 15 → redirect a `summary_path`.
- `update_rating` (AJAX/JSON): valida tipo y valor (1-5), llama `@entry.update_rating(tipo, valor)`, responde `render json: { ok: true }`
- `entry_params` permite: `fecha, palabra, hora_dormir, horas_dormidas, calidad_sueno, tipo_alto, sensacion, reflexion, micropausa, reflexion_final, pausa_estrella, proximo_foco, rutina`

### SummariesController
- `@completed_days`, `@fatigue_avgs = current_user.fatigue_averages`
- `@sleep_avg = current_user.sleep_average`
- `@top_tipo = @fatigue_avgs.max_by { |_, v| v }&.first`
- `@pausa_estrella`: del día 15 si existe, sino la última micro-pausa registrada (truncada a 120 chars)
- `@sorted_tipos = DiaryEntry::TIPO_LABELS.keys.sort_by { |k| -(@fatigue_avgs[k] || 0) }`

---

## Vistas — Estructura

```
app/views/
  layouts/application.html.erb   ← layout principal con brand bar
  shared/_flash.html.erb
  shared/_nav.html.erb           ← dots de navegación + progress bar
  sessions/new.html.erb          ← login (reemplaza el generado)
  registrations/new.html.erb
  diary_entries/show.html.erb    ← vista principal del día
  summaries/show.html.erb
```

---

## Lógica de vistas — show.html.erb (día del diario)

El formulario en `POST /diario/:day` con `form_with url: save_diary_day_path(@day)`:

1. **Day header**: número grande del día (estilo tipográfico), título, campo `date_field :fecha`, badge con cantidad de tipos
2. **Tipo nuevo reveal** (solo días 3,5,7,9,11,13): banner que presenta el tipo que se incorpora ese día con su descripción
3. **Pausa sugerida del día**: card con icono + texto de `@entry.pausa_sugerida`
4. **Palabra central**: `text_field :palabra`
5. **Ratings grid** (2 columnas): por cada tipo disponible, mostrar 5 dots clickeables (1-5). Los dots se actualizan vía AJAX con Stimulus sin recargar la página. Colores: 1-2 azul lavanda, 3 amarillo, 4-5 rojo.
6. **Tipo más alto** (días impares con múltiples tipos, no día 15): chips clickeables con radio button oculto para `tipo_alto`
7. **Registro de sueño**: grid 2 cols — `hora_dormir` (time_field), `horas_dormidas` (number_field step 0.5), `calidad_sueno` (select: Muy buena/Buena/Regular/Mala/Muy mala)
8. **Campo principal**:
   - Días pares (2,4,6,8,10) → `text_area :reflexion`
   - Resto → `text_area :sensacion`
9. **Micro-pausa** (días 1,3,5,7,9,11,12,13,14) → `text_area :micropausa`
10. **Campos especiales día 15**: `reflexion_final`, `pausa_estrella`, `proximo_foco`, `rutina`
11. **Botones**: "Guardar y continuar →" (submit con `name: "commit", value: "save_and_next"`) + "Guardar" (submit normal). Solo mostrar "continuar" si día < 15.

---

## Stimulus Controllers

### diary_controller.js
- `values`: `day` (Number), `updateRatingUrl` (String)
- Método `setRating(event)`: lee `event.params.tipo` y `event.params.valor`, actualiza UI (cambia `data-selected` y `data-level` en los dots del mismo tipo), hace fetch PATCH al server con JSON `{ tipo, valor }` y header CSRF.

### chips_controller.js
- Método `select(event)`: quita clase `active` de todos los chips del contenedor, agrega `active` al clickeado, y marca el radio button oculto correspondiente.

---

## CSS — Variables y estética

Paleta de la marca "Tu Pausa, Tu Esencia":

```css
:root {
  --lavender: #c8cfe8;
  --lavender-light: #eaecf6;
  --lavender-mid: #b0bae0;
  --green: #2d6a4f;
  --green-light: #52b788;
  --green-pale: #d8f3dc;
  --cream: #f7f4ef;
  --cream-dark: #ede8e0;
  --text: #2a2a35;
  --text-soft: #6b7280;
  --text-light: #9ca3af;
  --white: #ffffff;
}
```

**Tipografías** (Google Fonts):
- Display: `Cormorant Garamond` (300, 400, italic) — para títulos, número del día, section titles
- Body: `DM Sans` (300, 400, 500) — para todo el resto

**Fondo del body**: cream con gradientes radiales sutiles en lavanda y verde en las esquinas (position: fixed, pointer-events: none, z-index: 0).

**Elementos clave de diseño:**
- Cards blancas con `border-radius: 20-24px` y `box-shadow: 0 4px 28px rgba(0,0,0,0.07)`
- Rating dots: círculos 30px con borde lavanda. Cuando seleccionado: fondo lavanda (1-2), fondo amarillo #fbbf24 (3), fondo rojo #ef4444 (4-5)
- Botón primario: fondo `--green`, pill shape (border-radius 50px)
- Número del día: `font-size: 56px`, `color: var(--lavender-mid)`, `font-family: Cormorant Garamond`, peso 300
- Nav dots: 24px círculos. Estado: vacío (borde lavanda), completado (fondo green-pale + borde green), activo (fondo green sólido, scale 1.18), bloqueado (opacity 0.3)

**Banner "Empezá por acá"** (landing/index si no hay entries aún):
- Fondo `--green`, padding 22px 28px, border-radius 20px
- Flex row: icono grande + texto (eyebrow en caps pequeño + título Cormorant + subtítulo) + botón blanco a la derecha
- `box-shadow: 0 8px 28px rgba(45,106,79,0.25)`

---

## Layout principal (application.html.erb)

```erb
<div class="app-wrap">   <!-- max-width: 700px, margin: auto -->

  <!-- Brand bar -->
  <div class="brand-bar">  <!-- flex, space-between -->
    <div>🌿 Tu Pausa · Tu Esencia</div>
    <% if authenticated? %>
      <!-- Nombre de usuario + botón Salir (button_to sign_out_path, method: :delete) -->
    <% end %>
  </div>

  <!-- Flash messages -->
  <%= render "shared/flash" %>

  <%= yield %>

</div>
```

---

## Partial _nav.html.erb

Recibe locals: `completed_days` (array de ints), `current_day` (int).

- Fila de 15 dots (1-15). Dots accesibles son links a `diary_day_path(d)`, dots bloqueados son `<span>`.
- Un día es accesible si `d <= current_day || completed_days.include?(d)`.
- Botones: "?" (abre modal de instrucciones, puede ser simple `link_to "#instrucciones"`) y "Resumen" (`link_to summary_path`).
- Debajo: barra de progreso — `completed_days.length / 15 * 100` en porcentaje, color `--green`.

---

## Vista de resumen (summaries/show.html.erb)

1. Banner de completado (si hay 15 días guardados)
2. Grid 2 cols: días completados + promedio de sueño
3. Barras de tipos de cansancio ordenadas de mayor a menor promedio. Barra roja si avg >= 4, amarilla si >= 3, verde si < 3.
4. Insight del tipo predominante (descripción del tipo)
5. Card "Pausa estrella" con gradiente verde
6. Si día 15 tiene `proximo_foco` y `rutina`, mostrarlos en cards separadas
7. Link para volver al diario

---

## Flujo de usuario completo

1. Visita `/` → si no autenticada → redirect a `sign_in`
2. Si autenticada y sin entries → `diary_entries#index` → redirect a `diary_day_path(1)`
3. Si tiene entries → redirect al próximo día sin completar
4. Llena el formulario del día. Los ratings se guardan via AJAX instantáneamente (sin submit). El resto se guarda al hacer submit.
5. "Guardar y continuar" → guarda y va al día siguiente. "Guardar" → queda en el mismo día.
6. Al completar día 15 → redirect a resumen.
7. Puede navegar a cualquier día anterior usando los dots.
8. Puede ver el resumen en cualquier momento.

---

## Notas importantes

- Los **ratings NO van en el form** como campos normales. Se guardan via AJAX (Stimulus `diary_controller`) en el campo JSON `ratings` de la DB. El formulario principal solo guarda el resto de los campos de texto.
- El campo `ratings` es un TEXT en DB que almacena JSON: `'{"fisico":3,"mental":2}'`
- La autenticación de Rails 8 usa `Current.user`, `start_new_session_for`, `require_authentication` y `allow_unauthenticated_access`.
- Rails 8 genera automáticamente `Session` model, `Current` model, y el `SessionsController` base con `rails generate authentication`. Solo necesitás customizar la vista `sessions/new.html.erb`.
- El `RegistrationsController` **no** es generado por Rails, hay que crearlo manualmente.

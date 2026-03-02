# frozen_string_literal: true

class DiaryEntry < ApplicationRecord # rubocop:disable Metrics/ClassLength
  belongs_to :user

  validates :day_number, presence: true, inclusion: { in: 1..15 }
  validates :user_id, uniqueness: { scope: :day_number }

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
    15 => %w[fisico mental emocional sensorial social creativo espiritual],
  }.freeze

  TIPO_LABELS = {
    "fisico"     => { label: "Físico",     icon: "💪",
desc: "Tu cuerpo necesita movimiento y descanso físico real", },
    "mental"     => { label: "Mental",     icon: "🧠",
desc: "Tu mente necesita silencio, límites de información y claridad", },
    "emocional"  => { label: "Emocional",  icon: "💚",
desc: "Tu corazón necesita espacio para sentir sin performar", },
    "sensorial"  => { label: "Sensorial",  icon: "👁️",
desc: "Tus sentidos necesitan menos estímulos, menos pantallas", },
    "social"     => { label: "Social",     icon: "🤝",
desc: "Tu energía social necesita recarga en soledad o conexión genuina", },
    "creativo"   => { label: "Creativo",   icon: "🎨",
desc: "Tu creatividad necesita inspiración o permiso para no producir", },
    "espiritual" => { label: "Espiritual", icon: "🌿",
desc: "Tu sentido de propósito necesita reconexión con lo que importa", },
  }.freeze

  # rubocop:disable Layout/LineLength
  PAUSAS_SUGERIDAS = {
    1  => { icon: "🌬️",
            text: "Respiración 4-7-8: inhalá 4 segundos, retené 7, exhalá 8. Repetí 3 veces. Ideal antes de tu próximo paciente.", },
    2  => { icon: "🚶‍♀️",
            text: "Caminata de 5 minutos sin teléfono ni destino concreto. Solo mover el cuerpo y observar lo que hay alrededor.", },
    3  => { icon: "📋",
            text: "Vaciado mental: anotá durante 3 minutos todo lo que tenés 'abierto' en la mente, sin ordenar. Solo sacar.", },
    4  => { icon: "🧩",
            text: "Cierre de pestañas mentales: elegí una tarea inconclusa y definí cuándo la vas a retomar. Liberá ese espacio.", },
    5  => { icon: "🫁",
            text: "Pausa de check-in emocional: poné una mano en el pecho, cerrá los ojos y preguntate '¿qué emoción está presente ahora?' Sin juzgar.", },
    6  => { icon: "📓",
            text: "3 líneas de descarga emocional: escribí lo que sentís sin corregir, sin releer. Solo sacarlo afuera.", },
    7  => { icon: "🎵",
            text: "2 minutos de silencio intencional: apagá pantallas y notificaciones. Simplemente escuchá los sonidos del entorno.", },
    8  => { icon: "👀",
            text: "Descanso ocular: cerrá los ojos por 2 minutos con las palmas sobre ellos. Sentí el calor. Nada más.", },
    9  => { icon: "🏡",
            text: "Momento de cierre social: antes de llegar a casa, tomá 5 minutos sola en el auto. Sin hablar con nadie.", },
    10 => { icon: "☕",
            text: "Pausa sin pantalla: tomá un café o té y no revises el teléfono mientras lo hacés. Solo vos y la bebida.", },
    11 => { icon: "🎨",
            text: "Garabato libre: tomá una hoja y un lápiz y dibujá sin objetivo durante 3 minutos. No tiene que significar nada.", },
    12 => { icon: "🌿",
            text: "Salida a la naturaleza express: 5 minutos afuera, mirá algo verde o el cielo. Sin auriculares, sin pantallas.", },
    13 => { icon: "🙏",
            text: "Momento de gratitud silenciosa: cerrá los ojos y nombrá mentalmente 3 cosas pequeñas de hoy que te hicieron bien.", },
    14 => { icon: "✍️",
            text: "Una línea de propósito: escribí en una oración por qué hacés lo que hacés. Solo para recordártelo vos misma.", },
    15 => { icon: "🌸",
            text: "Hoy la micro-pausa es esta misma reflexión. Tomarte este tiempo ya es un acto de descanso consciente.", },
  }.freeze
  # rubocop:enable Layout/LineLength

  REFLEXION_DAYS  = [2, 4, 6, 8, 10].freeze
  MICROPAUSA_DAYS = [1, 3, 5, 7, 9, 11, 12, 13, 14].freeze

  def tipos_disponibles
    TIPOS_POR_DIA[day_number] || []
  end

  def ratings_hash
    JSON.parse(ratings.presence || "{}")
  rescue StandardError
    {}
  end

  def rating_for(tipo)
    ratings_hash[tipo.to_s].to_i
  end

  def update_rating(tipo, value)
    current = ratings_hash
    current[tipo.to_s] = value.to_i
    update(ratings: current.to_json)
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

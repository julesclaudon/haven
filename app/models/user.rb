class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :archetype, optional: true
  has_one :initial_quiz, dependent: :destroy
  has_many :states, dependent: :destroy
  has_many :chats, through: :states

  # Seuils pour débloquer l'archétype final
  ARCHETYPE_MIN_CLOSED_CHATS = 15
  ARCHETYPE_MIN_DAYS_SINCE_SIGNUP = 30

  # Vérifie si l'utilisateur a débloqué l'archétype final
  def archetype_unlocked?
    closed_chats_count >= ARCHETYPE_MIN_CLOSED_CHATS &&
      days_since_signup >= ARCHETYPE_MIN_DAYS_SINCE_SIGNUP
  end

  # Nombre de chats terminés (avec analyse)
  def closed_chats_count
    states.joins(:analysis).distinct.count
  end

  # Jours depuis l'inscription
  def days_since_signup
    (Date.current - created_at.to_date).to_i
  end

  # Progression vers le déblocage de l'archétype
  def archetype_unlock_progress
    {
      chats_progress: [closed_chats_count, ARCHETYPE_MIN_CLOSED_CHATS].min,
      chats_required: ARCHETYPE_MIN_CLOSED_CHATS,
      days_progress: [days_since_signup, ARCHETYPE_MIN_DAYS_SINCE_SIGNUP].min,
      days_required: ARCHETYPE_MIN_DAYS_SINCE_SIGNUP
    }
  end

  # Calcule l'archétype dominant basé sur tous les states
  # Pondération : les états récents comptent plus (Option C)
  def computed_dominant_archetype
    states_with_archetype = states.where.not(profil_relationnel: [nil, ''])
                                       .order(created_at: :desc)
    return nil if states_with_archetype.empty?

    # Pondération exponentielle : les plus récents comptent plus
    weighted_counts = Hash.new(0.0)
    total_states = states_with_archetype.count

    states_with_archetype.each_with_index do |state, index|
      # Plus l'index est petit (= plus récent), plus le poids est élevé
      # Formule : weight = 1 + (total - index) / total
      # Ex: pour 10 states, le plus récent a un poids de 2, le plus ancien de 1.1
      weight = 1.0 + (total_states - index).to_f / total_states
      weighted_counts[state.profil_relationnel] += weight
    end

    # Retourner l'archétype avec le score pondéré le plus élevé
    weighted_counts.max_by { |_, score| score }&.first
  end

  # Met à jour l'archétype utilisateur si débloqué
  def update_final_archetype!
    return unless archetype_unlocked?

    dominant = computed_dominant_archetype
    return unless dominant

    found_archetype = Archetype.find_by(archetype_name: dominant)
    update(archetype: found_archetype) if found_archetype
  end
end

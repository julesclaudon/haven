class State < ApplicationRecord
  belongs_to :user
  belongs_to :chat
  belongs_to :grief_stage

  validates :pain_level, numericality: {
    only_integer: true,
    in: 0..10
  }, allow_nil: true

  validates :time_of_day, inclusion: {
    in: %w[matin après-midi soir nuit],
    allow_nil: true
  }

  validates :trigger_source, inclusion: {
    in: %w[instagram facebook linkedin tiktok snapchat twitter mémoire message chanson lieu photo objet rêve autre],
    allow_nil: true
  }
end

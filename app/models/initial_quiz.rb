class InitialQuiz < ApplicationRecord
  belongs_to :user

  validates :age, numericality: { only_integer: true, greater_than: 13 }
  validates :relation_duration, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :pain_level, numericality: { only_integer: true, in: 0..10 }

  validates :age, presence: true
  validates :relation_end_date, presence: true
  validates :relation_duration, presence: true
  validates :pain_level, presence: true
  validates :breakup_type, presence: true
  validates :breakup_initiator, presence: true
  validates :emotion_label, presence: true
  validates :main_sentiment, presence: true
  validates :ex_contact_frequency, presence: true
  validates :considered_reunion, inclusion: { in: [true, false] }
  validates :ruminating_frequency, presence: true
  validates :sleep_quality, presence: true
  validates :habits_changed, presence: true
  validates :support_level, presence: true

end

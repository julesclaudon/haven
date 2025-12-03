class Chat < ApplicationRecord
  has_many :messages, dependent: :destroy
  has_one :state, dependent: :destroy
  has_one :user, through: :state

  validates :status, inclusion: { in: %w[active completed], allow_nil: true }
end

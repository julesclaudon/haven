class Chat < ApplicationRecord
  DEFAULT_TITLE = "Nouvelle conversation"

  has_many :messages, dependent: :destroy
  has_many :states, dependent: :destroy

  def generate_title_from_first_message
    first_message = messages.where(role: 'user').first
    return unless first_message

    new_title = first_message.content.truncate(50)
    update(status: new_title)
  end
end

class Chat < ApplicationRecord
  DEFAULT_TITLE = "Nouvelle conversation"
  CLOSED_PREFIX = "[TERMINÉE] "

  has_many :messages, dependent: :destroy
  has_many :states, dependent: :destroy
  has_many :users, through: :states

  def generate_title_from_first_message
    first_message = messages.where(role: 'user').first
    return unless first_message

    new_title = first_message.content.truncate(50)
    update(status: new_title)
  end

  def closed?
    status&.start_with?(CLOSED_PREFIX)
  end

  def close!
    return if closed?

    new_status = "#{CLOSED_PREFIX}#{display_title}"
    update!(status: new_status)
  end

  def update_title_after_close(new_title)
    return if new_title.blank?

    if closed?
      update!(status: "#{CLOSED_PREFIX}#{new_title}")
    else
      update!(status: new_title)
    end
  end

  def display_title
    return DEFAULT_TITLE if status.blank?

    status.sub(CLOSED_PREFIX, '')
  end
end

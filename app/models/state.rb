class State < ApplicationRecord
  belongs_to :user
  belongs_to :chat
  belongs_to :grief_stage
end

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :initial_quiz, dependent: :destroy
  has_many :states, dependent: :destroy
  has_many :chats, through: :states
end

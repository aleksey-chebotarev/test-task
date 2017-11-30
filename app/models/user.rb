class User < ApplicationRecord
  mount_uploader :avatar, AvatarUploader

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  before_validation :username_downcase

  scope :recent, -> { order(username: :asc) }

  validates :username, presence: true, uniqueness: true, length: { maximum: 39 }

  private

  def username_downcase
    self.username = username.downcase if username.present?
  end
end

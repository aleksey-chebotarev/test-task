class ForumUser < ApplicationRecord
  mount_uploader :avatar_image, AvatarUploader

  validates :username, presence: true, uniqueness: true

  before_save :set_last_scraped_date

  private

  def set_last_scraped_date
    self.last_scraped_date = DateTime.now
  end
end

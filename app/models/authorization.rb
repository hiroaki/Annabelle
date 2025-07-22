class Authorization < ApplicationRecord
  belongs_to :user

  validates :provider, :uid, presence: true
  validates :uid, uniqueness: { scope: :provider }
  validates :provider, uniqueness: { scope: :user_id }

  def self.provider_uid_exists?(provider, uid)
    where(provider: provider, uid: uid).exists?
  end
end

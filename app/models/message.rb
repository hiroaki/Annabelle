class Message < ApplicationRecord
  belongs_to :user
  has_many_attached :attachments, dependent: :purge_later
end

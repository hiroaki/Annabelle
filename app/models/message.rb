class Message < ApplicationRecord
  belongs_to :user
  has_many_attached :attachments, dependent: :purge_later

  validates :content, presence: true
  validate :content_within_request_body_limit

  private

  def content_within_request_body_limit
    max_request_body = Rails.configuration.x.max_request_body
    max_request_body = max_request_body.present? ? max_request_body.to_i : 0
    return if max_request_body <= 0
    return if content.blank?
    return if content.to_s.bytesize <= max_request_body

    errors.add(:content, :too_long, count: max_request_body)
  end
end

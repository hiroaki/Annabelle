# frozen_string_literal: true

# ImageMetadataAction は画像アップロード時のユーザー選択を記録する監査ログです。
# このレコードは削除されず、append-only で保存されます。
class ImageMetadataAction < ApplicationRecord
  belongs_to :user

  validates :blob_id, presence: true
  validates :action, presence: true, inclusion: { in: %w[upload] }
end

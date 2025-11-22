# frozen_string_literal: true

# ExtractImageMetadataJob は画像アップロード後に非同期で EXIF データを抽出し、
# blob の metadata に保存するジョブです。
#
# このジョブは Factory#create_message! から attachment 作成後にキューイングされます。
class ExtractImageMetadataJob < ApplicationJob
  queue_as :default

  def perform(blob_id)
    blob = ActiveStorage::Blob.find(blob_id)

    return unless ActiveStorage::Analyzer::ExifAnalyzer.accept?(blob)

    analyzer = ActiveStorage::Analyzer::ExifAnalyzer.new(blob)
    extracted = analyzer.metadata

    # exif のみを追加（width/height は analyzer が既に持っている）
    if extracted.key?(:exif)
      blob.update(metadata: blob.metadata.merge(extracted))
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn("[ExtractImageMetadataJob] Blob not found: #{blob_id}")
  rescue => e
    Rails.logger.error("[ExtractImageMetadataJob] Failed for blob #{blob_id}: #{e.class}: #{e.message}")
  end
end

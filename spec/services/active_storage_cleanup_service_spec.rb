require 'rails_helper'

RSpec.describe ActiveStorageCleanupService, type: :service do
  let(:logger) { instance_double(Logger, info: nil, :<< => nil) }
  let(:service) { described_class.new(days_old: 2, dry_run: dry_run, logger: logger) }

  # テストデータのセットアップ
  let!(:old_unattached_blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("old content"),
      filename: "old.txt",
      content_type: "text/plain"
    ).tap { |blob| blob.update(created_at: 3.days.ago) }
  end

  let!(:new_unattached_blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("new content"),
      filename: "new.txt",
      content_type: "text/plain"
    ).tap { |blob| blob.update(created_at: 1.day.ago) }
  end

  let!(:attached_blob) do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("attached content"),
      filename: "attached.txt",
      content_type: "text/plain"
    )
    blob.update(created_at: 3.days.ago)

    # 正規の方法でアタッチ（Messageモデルを使用）
    # FactoryBotを使用して親レコードを作成し、attachメソッドで紐付ける
    message = FactoryBot.create(:message)
    message.attachments.attach(blob)
    blob
  end

  describe '#call' do
    # テスト間の干渉を防ぐため、実行前にジョブキューをクリアする
    before do
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    end

    context 'when dry_run is true' do
      let(:dry_run) { true }

      it 'does not enqueue purge jobs' do
        expect {
          service.call
        }.not_to have_enqueued_job(ActiveStorage::PurgeJob)
      end

      it 'logs the blobs that would be purged correctly' do
        # Dry Runモードの開始ログ
        expect(logger).to receive(:info).with(/DRY RUN MODE/)

        # 削除対象のBlobが表示されること
        expect(logger).to receive(:info).with(/ID: #{old_unattached_blob.id}/)

        # 削除対象外のBlobが表示されないこと（重要）
        expect(logger).not_to receive(:info).with(/ID: #{new_unattached_blob.id}/)
        expect(logger).not_to receive(:info).with(/ID: #{attached_blob.id}/)

        # 集計結果が正しいこと（1件のみ）
        expect(logger).to receive(:info).with(/Total blobs found: 1/)

        # 合計サイズの表示（"old content" は 11 bytes）
        expect(logger).to receive(:info).with(/Total size: 11 Bytes/)

        service.call
      end
    end

    context 'when dry_run is false' do
      let(:dry_run) { false }

      # エンキューされたジョブのGlobalIDリストを取得するヘルパー
      let(:enqueued_gids) do
        ActiveJob::Base.queue_adapter.enqueued_jobs.map do |job|
          job[:args].first["_aj_globalid"]
        end
      end

      it 'enqueues purge job for old unattached blobs' do
        service.call
        # RSpecのhave_enqueued_jobマッチャを使うとN+1エラーになるため、直接検証
        expect(enqueued_gids).to include(old_unattached_blob.to_global_id.to_s)
      end

      it 'does not enqueue purge job for new or attached blobs' do
        service.call
        # 新しいBlobは削除対象外
        expect(enqueued_gids).not_to include(new_unattached_blob.to_global_id.to_s)
        # アタッチ済みBlobは削除対象外
        expect(enqueued_gids).not_to include(attached_blob.to_global_id.to_s)
      end

      it 'logs the execution details correctly' do
        expect(logger).to receive(:info).with(/=== EXECUTE MODE ===/)
        expect(logger).to receive(:info).with(/Purging unattached blobs created before/)
        expect(logger).to receive(:info).with(/Done. 1 blobs have been enqueued for deletion./)

        service.call
      end

      it 'prints progress dots for large number of blobs' do
        # N+1検知を一時的に無効化（テストデータ作成時のINSERT連打を許容）
        Prosopite.pause do
          # 50個以上のBlobを作成して、ドットが出力されることを確認
          50.times do |i|
            ActiveStorage::Blob.create_and_upload!(
              io: StringIO.new("content #{i}"),
              filename: "test_#{i}.txt",
              content_type: "text/plain"
            ).tap { |blob| blob.update(created_at: 3.days.ago) }
          end
        end

        # ドットが出力されること
        expect(logger).to receive(:<<).with('.')
        # 最後に改行が出力されること
        expect(logger).to receive(:<<).with("\n")

        service.call
      end
    end

    context 'edge cases' do
      let(:dry_run) { true }

      context 'when no unattached blobs exist older than specified days' do
        # 5日以上前のファイルを対象にする（3日前のファイルは対象外になるはず）
        let(:service) { described_class.new(days_old: 5, dry_run: dry_run, logger: logger) }

        it 'finds 0 blobs' do
          expect(logger).to receive(:info).with(/Total blobs found: 0/)
          service.call
        end
      end

      context 'when custom days_old is provided' do
        # 1日前より古いものを対象にする -> 1日前の new_unattached_blob も対象になるはず
        let(:service) { described_class.new(days_old: 1, dry_run: dry_run, logger: logger) }

        it 'includes blobs older than the custom days' do
          expect(logger).to receive(:info).with(/ID: #{new_unattached_blob.id}/)
          expect(logger).to receive(:info).with(/ID: #{old_unattached_blob.id}/)
          expect(logger).to receive(:info).with(/Total blobs found: 2/)
          service.call
        end
      end

      context 'when logger is not provided' do
        # デフォルト引数の動作確認
        let(:service) { described_class.new(days_old: 2, dry_run: dry_run) }

        it 'uses default logger (stdout) without error' do
          # 標準出力への出力を検証
          expect { service.call }.to output(/=== DRY RUN MODE ===/).to_stdout
        end
      end

      context 'when invalid days_old is provided' do
        it 'raises InvalidDaysOldError for negative number' do
          expect {
            described_class.new(days_old: -1, dry_run: dry_run, logger: logger)
          }.to raise_error(ActiveStorageCleanupService::InvalidDaysOldError)
        end

        it 'raises InvalidDaysOldError for zero' do
          expect {
            described_class.new(days_old: 0, dry_run: dry_run, logger: logger)
          }.to raise_error(ActiveStorageCleanupService::InvalidDaysOldError)
        end

        it 'raises InvalidDaysOldError for float number' do
          expect {
            described_class.new(days_old: 1.5, dry_run: dry_run, logger: logger)
          }.to raise_error(ActiveStorageCleanupService::InvalidDaysOldError)
        end

        it 'raises InvalidDaysOldError for invalid string' do
          expect {
            described_class.new(days_old: "invalid", dry_run: dry_run, logger: logger)
          }.to raise_error(ActiveStorageCleanupService::InvalidDaysOldError)
        end

        it 'accepts valid string number' do
          expect {
            described_class.new(days_old: "5", dry_run: dry_run, logger: logger)
          }.not_to raise_error
        end
      end
    end
  end
end

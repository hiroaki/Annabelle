# ActiveStorage の孤立ファイル（どのモデルにもアタッチされていない Blob）を削除するタスク
#
# 使い方:
#   # 確認（Dry Run）: 削除対象のリストと合計サイズを表示
#   rake active_storage:cleanup
#
#   # 実行（削除）: 実際に削除を実行（purge_later）
#   rake active_storage:cleanup FORCE=true
#
#   # オプション:
#   #   DAYS_OLD: 作成から指定した日数以上経過したファイルを対象とする（デフォルト: 2）
#   rake active_storage:cleanup DAYS_OLD=7

namespace :active_storage do
  desc "Purges unattached Active Storage blobs. Default is dry-run. Use FORCE=true to execute."
  task cleanup: :environment do
    # 安全のため、作成から一定期間経過したものを対象とする（デフォルト2日）
    # アップロード直後のファイルなどを誤って削除しないための猶予期間
    days_old = ENV.fetch("DAYS_OLD", 2).to_i
    cutoff_period = days_old.days.ago

    # 未アタッチかつ古いBlobを検索
    # unattached スコープは ActiveStorage::Blob で定義されている
    unattached_blobs = ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at <= ?", cutoff_period)

    # FORCE環境変数が "true" でない限り、Dry Run モードとする
    is_dry_run = ENV["FORCE"] != "true"

    if is_dry_run
      puts "=== DRY RUN MODE ==="
      puts "Searching for unattached blobs created before #{cutoff_period}..."
      puts "The following blobs would be purged:"

      count = 0
      total_size = 0

      unattached_blobs.find_each do |blob|
        puts "ID: #{blob.id} | Filename: #{blob.filename} | Created: #{blob.created_at} | Size: #{ActiveSupport::NumberHelper.number_to_human_size(blob.byte_size)}"
        count += 1
        total_size += blob.byte_size
      end

      puts "--------------------"
      puts "Total blobs found: #{count}"
      puts "Total size: #{ActiveSupport::NumberHelper.number_to_human_size(total_size)}"
      puts ""
      puts "To actually purge these files, run the task with FORCE=true:"
      puts "  rake active_storage:cleanup FORCE=true"
    else
      puts "=== EXECUTE MODE ==="
      puts "Purging unattached blobs created before #{cutoff_period}..."

      count = 0
      unattached_blobs.find_each do |blob|
        blob.purge_later
        count += 1
        print "." if count % 50 == 0
      end

      puts "\nDone. #{count} blobs have been enqueued for deletion."
    end
  end
end

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
  desc 'Purges unattached Active Storage blobs. Default is dry-run. Use FORCE=true to execute.'
  task cleanup: :environment do
    # 安全のため、作成から一定期間経過したものを対象とする（デフォルト2日）
    # アップロード直後のファイルなどを誤って削除しないための猶予期間
    days_old = ENV.fetch('DAYS_OLD', 2).to_i

    # FORCE環境変数が "true" でない限り、Dry Run モードとする
    is_dry_run = ENV['FORCE'] != 'true'

    ActiveStorageCleanupService.new(days_old: days_old, dry_run: is_dry_run).call
  end
end

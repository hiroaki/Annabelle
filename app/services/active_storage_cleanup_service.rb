# Service to safely purge unattached Active Storage blobs.
#
# It finds blobs that are not attached to any record and are older than a specified
# number of days (default: 2), then purges them.
#
# Usage:
#   ActiveStorageCleanupService.new(days_old: 7, dry_run: false).call
#
class ActiveStorageCleanupService
  def initialize(days_old: 2, dry_run: true, logger: Logger.new($stdout))
    @days_old = days_old
    @dry_run = dry_run
    @logger = logger
  end

  def call
    cutoff_period = @days_old.days.ago
    unattached_blobs = ActiveStorage::Blob.unattached.where('active_storage_blobs.created_at <= ?', cutoff_period)

    if @dry_run
      perform_dry_run(unattached_blobs, cutoff_period)
    else
      perform_cleanup(unattached_blobs, cutoff_period)
    end
  end

  private

  def perform_dry_run(blobs, cutoff_period)
    @logger.info '=== DRY RUN MODE ==='
    @logger.info "Searching for unattached blobs created before #{cutoff_period}..."
    @logger.info 'The following blobs would be purged:'

    count = 0
    total_size = 0

    blobs.find_each do |blob|
      @logger.info "ID: #{blob.id} | Filename: #{blob.filename} | Created: #{blob.created_at} | Size: #{ActiveSupport::NumberHelper.number_to_human_size(blob.byte_size)}"
      count += 1
      total_size += blob.byte_size
    end

    @logger.info '--------------------'
    @logger.info "Total blobs found: #{count}"
    @logger.info "Total size: #{ActiveSupport::NumberHelper.number_to_human_size(total_size)}"
    @logger.info ''
    @logger.info 'To actually purge these files, run with dry_run: false'
  end

  def perform_cleanup(blobs, cutoff_period)
    @logger.info '=== EXECUTE MODE ==='
    @logger.info "Purging unattached blobs created before #{cutoff_period}..."

    count = 0
    progress_printed = false

    blobs.find_each do |blob|
      blob.purge_later
      count += 1
      if count % 50 == 0
        @logger.print '.'
        progress_printed = true
      end
    end

    # ドットが出力されていて、かつ最後の出力で行が変わっていない場合は改行を入れる
    @logger.print "\n" if progress_printed

    @logger.info "Done. #{count} blobs have been enqueued for deletion."
  end
end

# Service to safely purge unattached Active Storage blobs.
#
# It finds blobs that are not attached to any record and are older than a specified
# number of days (default: 2), then purges them.
#
# Usage:
#   ActiveStorageCleanupService.new(days_old: 7, dry_run: false).call
#
class ActiveStorageCleanupService
  class InvalidDaysOldError < StandardError; end

  def initialize(days_old: 2, dry_run: true, logger: Logger.new($stdout))
    @days_old = validate_days_old(days_old)
    @dry_run = dry_run
    @logger = logger
  end

  # Returns a Hash with execution results (count, total_size, dry_run).
  # Note: The return structure may be revisited in the future as requirements evolve.
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

  def validate_days_old(value)
    # nil の場合はデフォルト値 2 を採用する
    return 2 if value.nil?

    # 数値の場合（整数のみ許可）
    if value.is_a?(Integer)
      raise InvalidDaysOldError, 'days_old must be a positive integer' unless value > 0
      return value
    end

    # 文字列の場合（正の整数のみ許可）
    if value.is_a?(String) && value =~ /\A[1-9]\d*\z/
      return value.to_i
    end

    raise InvalidDaysOldError, "days_old must be a positive integer, got: #{value.inspect}"
  end

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

    { count: count, total_size: total_size, dry_run: true }
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
        # Intentionally use << (no newline) to show progress dots on the same line every 50 blobs.
        @logger << '.'
        progress_printed = true
      end
    end

    # ドットが出力されていて、かつ最後の出力で行が変わっていない場合は改行を入れる
    @logger << "\n" if progress_printed

    @logger.info "Done. #{count} blobs have been enqueued for deletion."

    { count: count, dry_run: false }
  end
end

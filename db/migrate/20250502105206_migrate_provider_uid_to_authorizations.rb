class MigrateProviderUidToAuthorizations < ActiveRecord::Migration[8.0]
  def up
    # Check for duplicates: same provider and uid used by multiple users
    duplicates = User
      .where.not(provider: nil, uid: nil)
      .group(:provider, :uid)
      .having("COUNT(*) > 1")
      .pluck(:provider, :uid)

    if duplicates.any?
      raise ActiveRecord::IrreversibleMigration, <<~MSG
        Duplicate provider/uid combinations detected in users table:
        #{duplicates.map { |p, u| "- provider: #{p}, uid: #{u}" }.join("\n")}
        Please ensure each (provider, uid) pair is unique before running this migration.
      MSG
    end

    say_with_time "Migrating provider/uid to authorizations" do
      User.where.not(provider: nil, uid: nil).find_each do |user|
        Authorization.find_or_create_by!(
          user_id: user.id,
          provider: user.provider,
          uid: user.uid
        )
      end
    end

    remove_column :users, :provider
    remove_column :users, :uid
  end

  def down
    add_column :users, :provider, :string
    add_column :users, :uid, :string

    say_with_time "Restoring provider/uid from authorizations (oldest record per user)" do
      User.reset_column_information

      # いちばん古いレコードを採用して users テーブルに戻します。
      # #up 時にはそのレコードが移行されているから。
      Authorization
        .joins(:user)
        .select('authorizations.user_id, authorizations.provider, authorizations.uid, authorizations.created_at, users.id as user_id')
        .order('authorizations.user_id ASC, authorizations.created_at ASC')
        .each do |auth|
          user = User.find_by(id: auth.user_id)
          user.update_columns(provider: auth.provider, uid: auth.uid) if user
        end
    end

    say_with_time "Deleting authorizations" do
      Authorization.delete_all
    end
  end
end

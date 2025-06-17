class AddUserToMessages < ActiveRecord::Migration[8.0]
  def up
    add_reference :messages, :user, foreign_key: true, null: true

    # ダミーadminユーザーをSQLで直接作成
    now = Time.current.utc.strftime('%Y-%m-%d %H:%M:%S')
    encrypted_password = User.new.send(:password_digest, SecureRandom.hex(16))
    execute <<~SQL
      INSERT INTO users (email, encrypted_password, admin, created_at, updated_at)
      SELECT 'migration_admin_' || strftime('%s','now') || '@localhost',
             '#{encrypted_password}',
             1,
             '#{now}',
             '#{now}'
      WHERE NOT EXISTS (SELECT 1 FROM users WHERE admin = 1)
    SQL

    admin_id = select_value("SELECT id FROM users WHERE admin = 1 ORDER BY id ASC LIMIT 1")
    Message.reset_column_information
    Message.where(user_id: nil).update_all(user_id: admin_id)

    change_column_null :messages, :user_id, false
  end

  def down
    remove_reference :messages, :user, foreign_key: true
  end
end

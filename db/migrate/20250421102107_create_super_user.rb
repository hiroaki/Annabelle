class CreateSuperUser < ActiveRecord::Migration[8.0]
  def up
    now = Time.current.utc.strftime('%Y-%m-%d %H:%M:%S')
    encrypted_password = User.new.send(:password_digest, 'YOU MUST CHANGE THIS')
    execute <<~SQL
      INSERT INTO users (email, encrypted_password, admin, created_at, updated_at)
      VALUES (
        'admin@localhost',
        '#{encrypted_password}',
        1,
        '#{now}',
        '#{now}'
      )
    SQL
  end

  def down
    execute <<~SQL
      DELETE FROM users WHERE email = 'admin@localhost' AND admin = 1
    SQL
  end
end

class AddDeviseTwoFactorBackupableToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :otp_backup_codes, :text
  end
end

class AddPreferredLanguageToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :preferred_language, :string, null: false, default: ''
  end
end

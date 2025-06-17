class CreateAuthorizations < ActiveRecord::Migration[8.0]
  def change
    create_table :authorizations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false

      t.timestamps
    end

    add_index :authorizations, [:provider, :uid], unique: true
  end
end

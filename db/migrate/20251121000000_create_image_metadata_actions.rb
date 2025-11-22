class CreateImageMetadataActions < ActiveRecord::Migration[8.0]
  def change
    create_table :image_metadata_actions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :blob_id, null: false
      t.string :action, null: false, default: 'upload'
      t.boolean :strip_metadata, null: false, default: false
      t.boolean :allow_location_public, null: false, default: false
      t.string :ip_address
      t.text :user_agent
      t.timestamps

      t.index :blob_id
      t.index [:user_id, :created_at]
    end
  end
end

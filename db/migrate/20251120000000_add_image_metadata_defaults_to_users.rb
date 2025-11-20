class AddImageMetadataDefaultsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :default_strip_metadata, :boolean, null: false, default: true
    add_column :users, :default_allow_location_public, :boolean, null: false, default: false
    add_column :users, :show_image_location_on_preview, :boolean, null: false, default: true
  end
end

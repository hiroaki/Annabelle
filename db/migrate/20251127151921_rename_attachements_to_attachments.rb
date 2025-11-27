class RenameAttachementsToAttachments < ActiveRecord::Migration[8.1]
  def up
    # Update any existing ActiveStorage::Attachment records that have the typo
    # This will rename 'attachements' to 'attachments' in the name column
    ActiveStorage::Attachment.where(name: 'attachements').update_all(name: 'attachments')
  end

  def down
    # Revert the change if needed (though this is unlikely to be necessary)
    ActiveStorage::Attachment.where(name: 'attachments').update_all(name: 'attachements')
  end
end

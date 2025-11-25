module MessagesHelper
  def image_location_options(attachment)
    metadata = attachment.blob.metadata || {}
    exif = metadata['exif'] || {}
    gps = exif['gps']
    upload_settings = metadata['upload_settings'] || {}
    allow_public = upload_settings['allow_location_public']

    is_public = allow_public == true || allow_public == 'true'

    if gps.present? && is_public
      {
        data: {
          latitude: gps['latitude'],
          longitude: gps['longitude']
        }
      }
    else
      {}
    end
  end
end

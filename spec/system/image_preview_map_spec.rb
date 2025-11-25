require 'rails_helper'

RSpec.describe 'Image Preview Map', type: :system do
  let(:user) { create(:user, show_image_location_on_preview: true) }
  let(:message) { create(:message, user: user) }

  before do
    login_as user, scope: :user
  end

  context 'when image has GPS and location is public' do
    before do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join('spec/fixtures/files/image_with_gps.jpg')),
        filename: 'image_with_gps.jpg',
        content_type: 'image/jpeg'
      )
      blob.metadata.merge!({
        'exif' => { 'gps' => { 'latitude' => 35.681236, 'longitude' => 139.767125 } },
        'upload_settings' => { 'allow_location_public' => true }
      })
      blob.save!
      message.attachements.attach(blob)
    end

    it 'shows the map in preview' do
      visit root_path

      # Click the image to open preview
      find("div[data-filename='image_with_gps.jpg']").click

      expect(page).to have_selector('iframe[src*="openstreetmap.org"]')
    end
  end

  context 'when location is not public' do
    before do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join('spec/fixtures/files/image_with_gps.jpg')),
        filename: 'image_with_gps.jpg',
        content_type: 'image/jpeg'
      )
      blob.metadata.merge!({
        'exif' => { 'gps' => { 'latitude' => 35.681236, 'longitude' => 139.767125 } },
        'upload_settings' => { 'allow_location_public' => false }
      })
      blob.save!
      message.attachements.attach(blob)
    end

    it 'does not show the map' do
      visit root_path
      find("div[data-filename='image_with_gps.jpg']").click
      expect(page).not_to have_selector('iframe[src*="openstreetmap.org"]')
    end
  end

  context 'when user disabled map preview' do
    let(:user) { create(:user, show_image_location_on_preview: false) }

    before do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join('spec/fixtures/files/image_with_gps.jpg')),
        filename: 'image_with_gps.jpg',
        content_type: 'image/jpeg'
      )
      blob.metadata.merge!({
        'exif' => { 'gps' => { 'latitude' => 35.681236, 'longitude' => 139.767125 } },
        'upload_settings' => { 'allow_location_public' => true }
      })
      blob.save!
      message.attachements.attach(blob)
    end

    it 'does not show the map' do
      visit root_path
      find("div[data-filename='image_with_gps.jpg']").click
      expect(page).not_to have_selector('iframe[src*="openstreetmap.org"]')
    end
  end
end

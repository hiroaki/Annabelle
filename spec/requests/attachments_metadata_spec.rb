require 'rails_helper'

RSpec.describe 'Attachments metadata endpoint', type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  it 'returns latitude/longitude when metadata present and public' do
    path = Rails.root.join('spec/fixtures/files/test_image.jpg')
    blob = ActiveStorage::Blob.create_and_upload!(io: File.open(path, 'rb'), filename: 'test_image.jpg', content_type: 'image/jpeg')

    # attach to a record (Message) so we have an attachment record
    message = Message.create!(content: 'hello', user: user)
    attachment = ActiveStorage::Attachment.create!(name: 'attachments', record: message, blob: blob)

    # set metadata as server would
    blob.update!(metadata: {
      'exif' => { 'gps' => { 'latitude' => 35.681236, 'longitude' => 139.767125 } },
      'upload_settings' => { 'allow_location_public' => true }
    })

    get metadata_attachment_path(attachment, locale: 'en')

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json['latitude']).to be_within(0.000001).of(35.681236)
    expect(json['longitude']).to be_within(0.000001).of(139.767125)
  end

  it 'returns empty JSON when metadata present but not public' do
    path = Rails.root.join('spec/fixtures/files/test_image.jpg')
    blob = ActiveStorage::Blob.create_and_upload!(io: File.open(path, 'rb'), filename: 'test_image.jpg', content_type: 'image/jpeg')
    message = Message.create!(content: 'hello', user: user)
    attachment = ActiveStorage::Attachment.create!(name: 'attachments', record: message, blob: blob)

    blob.update!(metadata: {
      'exif' => { 'gps' => { 'latitude' => 35.0, 'longitude' => 139.0 } },
      'upload_settings' => { 'allow_location_public' => false }
    })

    get metadata_attachment_path(attachment, locale: 'en')

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json).to eq({})
  end

  it 'returns 404 and empty body when attachment not found' do
    get '/en/attachments/999999/metadata'
    expect(response).to have_http_status(:not_found)
    json = JSON.parse(response.body)
    expect(json).to eq({})
  end

  it 'requires authentication (returns 401) when not signed in' do
    # create an attachment to request
    path = Rails.root.join('spec/fixtures/files/test_image.jpg')
    blob = ActiveStorage::Blob.create_and_upload!(io: File.open(path, 'rb'), filename: 'test_image.jpg', content_type: 'image/jpeg')
    message = Message.create!(content: 'hello', user: user)
    attachment = ActiveStorage::Attachment.create!(name: 'attachments', record: message, blob: blob)

    # sign out the current user to simulate unauthenticated access
    sign_out user

    get metadata_attachment_path(attachment, locale: 'en'), headers: { 'ACCEPT' => 'application/json' }

    expect(response).to have_http_status(:unauthorized)
  end
end

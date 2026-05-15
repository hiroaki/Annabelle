require 'rails_helper'

RSpec.describe 'Attachments metadata endpoint', type: :request do
  let(:user) { create(:user) }
  let(:path) { Rails.root.join('spec/fixtures/files/test_image.jpg') }
  let(:blob) { ActiveStorage::Blob.create_and_upload!(io: File.open(path, 'rb'), filename: 'test_image.jpg', content_type: 'image/jpeg') }
  let(:message) { Message.create!(content: 'hello', user: user) }
  let(:attachment) { ActiveStorage::Attachment.create!(name: 'attachments', record: message, blob: blob) }

  before do
    sign_in user
  end

  it 'returns latitude/longitude when metadata present and public' do
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
    blob.update!(metadata: {
      'exif' => { 'gps' => { 'latitude' => 35.0, 'longitude' => 139.0 } },
      'upload_settings' => { 'allow_location_public' => false }
    })

    get metadata_attachment_path(attachment, locale: 'en')

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json).to eq({})
  end

  it 'streams an attachment for authenticated users' do
    get blob_attachment_path(attachment, locale: 'en')

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('image/jpeg')
    expect(response.headers['Accept-Ranges']).to eq('bytes')
  end

  it 'downloads an attachment for authenticated users' do
    get download_attachment_path(attachment, locale: 'en')

    expect(response).to have_http_status(:ok)
    expect(response.headers['Content-Disposition']).to include('attachment')
  end

  it 'streams a representation for authenticated users' do
    variation_key = ActiveStorage::Variation.wrap(resize_to_limit: [640, 480]).key

    get representation_attachment_path(attachment, variation_key: variation_key, locale: 'en')

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('image/jpeg')
  end

  it 'returns 404 and empty body when attachment not found' do
    get '/en/attachments/999999/metadata'
    expect(response).to have_http_status(:not_found)
    json = JSON.parse(response.body)
    expect(json).to eq({})
  end

  it 'returns 404 when attachment does not belong to a message' do
    other_attachment = ActiveStorage::Attachment.create!(name: 'avatar', record: user, blob: blob)

    get blob_attachment_path(other_attachment, locale: 'en')

    expect(response).to have_http_status(:not_found)
  end

  it 'requires authentication (returns 401) when not signed in' do
    # sign out the current user to simulate unauthenticated access
    sign_out user

    get metadata_attachment_path(attachment, locale: 'en'), headers: { 'ACCEPT' => 'application/json' }

    expect(response).to have_http_status(:unauthorized)
  end

  it 'requires authentication for attachment content routes' do
    variation_key = ActiveStorage::Variation.wrap(resize_to_limit: [640, 480]).key

    sign_out user

    get blob_attachment_path(attachment, locale: 'en'), headers: { 'ACCEPT' => 'application/octet-stream' }
    expect(response).to have_http_status(:unauthorized)

    get download_attachment_path(attachment, locale: 'en'), headers: { 'ACCEPT' => 'application/octet-stream' }
    expect(response).to have_http_status(:unauthorized)

    get representation_attachment_path(attachment, variation_key: variation_key, locale: 'en'), headers: { 'ACCEPT' => 'image/jpeg' }
    expect(response).to have_http_status(:unauthorized)
  end
end

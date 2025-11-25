require 'rails_helper'

RSpec.describe 'Current user meta tags', type: :system do
  let(:user) { create(:user, show_image_location_on_preview: true) }

  before do
    login_as(user, scope: :user)
  end

  it 'renders current-user-id and show-location meta tags in the head' do
    visit '/en'

    # Meta tags are in head and not visible; use visible: false to find them
    id_meta = page.find('head meta[name="current-user-id"]', visible: false)
    expect(id_meta[:content]).to eq(user.id.to_s)

    show_meta = page.find('head meta[name="current-user-show-location-preview"]', visible: false)
    expect(show_meta[:content]).to eq(user.show_image_location_on_preview.to_s)
  end
end

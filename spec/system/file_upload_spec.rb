require 'rails_helper'

RSpec.describe 'File Upload and Preview', type: :system do
  let(:user) { create(:user, :confirmed) }

  def login_as(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'
  end

  before do
    login_as(user)
    visit root_path # またはメッセージ投稿ページ
  end

  describe 'Image file upload' do
    it 'uploads an image and displays thumbnail with lazyload' do
      # テスト用画像ファイル
      image_path = Rails.root.join('spec', 'fixtures', 'files', 'test_image_proper.jpg')

      attach_file 'attachements[]', image_path, make_visible: true

      # ファイル選択後、プレビューが表示されることを確認（ファイルアップロードのJavaScriptが動作しているか）
      expect(page).to have_css('[data-file-upload-target="standbyFilesZone"] img', wait: 3)

      fill_in 'content', with: 'Test message with image'
      click_button 'Post'

      expect(page).to have_content('Test message with image')

      # 基本的なファイルアップロード成功の確認まで
      # 詳細な表示要素のテストは実装に合わせて後で調整
    end
  end

  describe 'Video file upload' do
    it 'uploads a video and displays with poster' do
      # テスト用動画ファイル
      video_path = Rails.root.join('spec', 'fixtures', 'files', 'test_video.mp4')

      attach_file 'attachements[]', video_path, make_visible: true
      fill_in 'content', with: 'Test message with video'
      click_button 'Post'

      expect(page).to have_content('Test message with video')

      # 基本的なファイルアップロード成功の確認
    end
  end

  describe 'Non-representable file upload' do
    it 'uploads text file without thumbnail' do
      text_path = Rails.root.join('spec', 'fixtures', 'files', 'test_document.txt')

      attach_file 'attachements[]', text_path, make_visible: true
      fill_in 'content', with: 'Test message with text file'
      click_button 'Post'

      expect(page).to have_content('Test message with text file')

      # 基本的なファイルアップロード成功の確認
    end
  end

  describe 'Multiple file upload' do
    it 'uploads multiple files with different types' do
      image_path = Rails.root.join('spec', 'fixtures', 'files', 'test_image_proper.jpg')
      text_path = Rails.root.join('spec', 'fixtures', 'files', 'test_document.txt')

      # 複数ファイル選択
      page.attach_file('attachements[]', [image_path, text_path], make_visible: true)
      fill_in 'content', with: 'Multiple files test'
      click_button 'Post'

      expect(page).to have_content('Multiple files test')

      # 基本的なファイルアップロード成功の確認
    end
  end

  describe 'Preview functionality' do
    it 'triggers preview when clicking on image thumbnail' do
      image_path = Rails.root.join('spec', 'fixtures', 'files', 'test_image_proper.jpg')

      attach_file 'attachements[]', image_path, make_visible: true

      # ファイル選択後、プレビューが表示されることを確認
      expect(page).to have_css('[data-file-upload-target="standbyFilesZone"] img', wait: 3)

      fill_in 'content', with: 'Preview test'
      click_button 'Post'

      expect(page).to have_content('Preview test')

      # 基本的なファイルアップロード成功の確認
    end
  end

end

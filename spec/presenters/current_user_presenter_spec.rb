# Claude generated (not GitHub Copilot with GPT-4.1)
require 'rails_helper'

RSpec.describe CurrentUserPresenter, type: :presenter do
  let(:view_context) { double('view_context') }
  let(:user) { create(:user, username: 'testuser') }
  let(:presenter) { described_class.new(view_context, user) }

  before do
    # ActionView::Base のインスタンスとして認識させる
    allow(view_context).to receive(:kind_of?).with(ActionView::Base).and_return(true)

    # 基本的なヘルパーメソッドをモック化
    allow(view_context).to receive(:user_signed_in?).and_return(true)
    allow(view_context).to receive(:user_path).with(user).and_return('/users/1')
    allow(view_context).to receive(:destroy_user_session_path).and_return('/users/sign_out')

    # data_with_testidヘルパーの動作をモック化（非production環境想定）
    allow(Rails).to receive(:env).and_return(double(production?: false))
    allow(view_context).to receive(:data_with_testid) do |testid, extra = {}|
      { data: extra.merge(testid: testid) }
    end

    # HTML生成系メソッドをモック化
    allow(view_context).to receive(:tag).and_return(double('tag_helper'))
    allow(view_context.tag).to receive(:meta).and_return('<meta name="current-user-id" content="1">')
    allow(view_context).to receive(:link_to).and_return('<a href="#">Link</a>')
    allow(view_context).to receive(:safe_join).and_return('<div>Joined content</div>')
    allow(view_context).to receive(:content_tag).and_return('<span>Content</span>')
  end

  describe '.username_display_dom_id' do
    it 'returns the correct DOM ID' do
      expect(described_class.username_display_dom_id).to eq('user-name-display')
    end
  end

  describe '#initialize' do
    context 'when model is nil' do
      it 'creates a new User instance' do
        presenter = described_class.new(view_context, nil)
        expect(presenter.user).to be_a(User)
        expect(presenter.user).to be_new_record
      end
    end

    context 'when model is a User' do
      it 'uses the provided user' do
        expect(presenter.user).to eq(user)
      end
    end

    context 'when model is not a User' do
      it 'raises ArgumentError' do
        expect {
          described_class.new(view_context, 'not_a_user')
        }.to raise_error(ArgumentError, 'Expected User, got String')
      end
    end

    context 'when view_context is not ActionView::Base' do
      before do
        allow(view_context).to receive(:kind_of?).with(ActionView::Base).and_return(false)
      end

      it 'raises ArgumentError' do
        expect {
          described_class.new(view_context, user)
        }.to raise_error(ArgumentError, /Expected ActionView::Base/)
      end
    end
  end

  describe '#user' do
    it 'returns the model' do
      expect(presenter.user).to eq(user)
    end
  end

  describe '#meta_tag' do
    context 'when user is signed in' do
      before do
        allow(view_context).to receive(:user_signed_in?).and_return(true)
      end

      it 'returns meta tag with current user id' do
        expect(view_context.tag).to receive(:meta)
          .with(name: 'current-user-id', content: user.id)
          .and_return('<meta name="current-user-id" content="1">')

        result = presenter.meta_tag
        expect(result).to eq('<meta name="current-user-id" content="1">')
      end
    end

    context 'when user is not signed in' do
      before do
        allow(view_context).to receive(:user_signed_in?).and_return(false)
      end

      it 'returns empty string' do
        expect(presenter.meta_tag).to eq('')
      end
    end
  end

  describe '#links' do
    context 'when user is signed in' do
      before do
        allow(view_context).to receive(:user_signed_in?).and_return(true)
      end

      it 'generates user links with correct parameters' do
        expect(view_context).to receive(:link_to).with(
          user.username,
          '/users/1',
          hash_including(
            class: 'text-gray-400',
            id: 'user-name-display',
            data: { testid: 'current-user-display' }
          )
        ).and_return('<a href="/users/1">testuser</a>')

        expect(view_context).to receive(:link_to).with(
          I18n.t('layouts.configuration_menu.sign_out'),
          '/users/sign_out',
          hash_including(
            method: :delete,
            class: 'text-gray-400',
            data: { testid: 'current-user-signout', turbo_method: :delete }
          )
        ).and_return('<a href="/users/sign_out">Sign out</a>')

        expect(view_context).to receive(:safe_join)
          .with(array_including(String, String))
          .and_return('<div>User links</div>')

        result = presenter.links
        expect(result).to eq('<div>User links</div>')
      end

      it 'includes data-testid attributes' do
        expect(view_context).to receive(:data_with_testid)
          .with('current-user-display')
          .and_return({ data: { testid: 'current-user-display' } })

        expect(view_context).to receive(:data_with_testid)
          .with('current-user-signout', turbo_method: :delete)
          .and_return({ data: { testid: 'current-user-signout', turbo_method: :delete } })

        presenter.links
      end
    end

    context 'when user is not signed in' do
      before do
        allow(view_context).to receive(:user_signed_in?).and_return(false)
      end

      it 'returns empty string' do
        expect(presenter.links).to eq('')
      end
    end
  end

  describe '#notification_badge' do
    context 'when user is signed in' do
      before do
        allow(view_context).to receive(:user_signed_in?).and_return(true)
      end

      it 'generates notification badge with correct structure' do
        expect(view_context).to receive(:content_tag)
          .with(:span, 'Notifications', class: 'sr-only')
          .and_return('<span class="sr-only">Notifications</span>')

        expect(view_context).to receive(:content_tag)
          .with(:div, '&nbsp;'.html_safe, hash_including(
            data: { messages_channel: 'notification' },
            class: 'absolute inline-flex items-center justify-center w-4 h-4 text-xs text-white bg-red-500 border-white rounded-full -top-1 -end-1 hidden'
          ))
          .and_return('<div data-messages-channel="notification">Badge</div>')

        result = presenter.notification_badge
        expect(result).to include('Notifications')
        expect(result).to include('Badge')
      end
    end

    context 'when user is not signed in' do
      before do
        allow(view_context).to receive(:user_signed_in?).and_return(false)
      end

      it 'returns empty string' do
        expect(presenter.notification_badge).to eq('')
      end
    end
  end

  describe 'method delegation to view_context' do
    it 'delegates missing methods to view_context' do
      allow(view_context).to receive(:respond_to?).with(:some_helper_method).and_return(true)
      allow(view_context).to receive(:some_helper_method).and_return('helper result')

      expect(presenter.some_helper_method).to eq('helper result')
    end

    it 'raises NoMethodError for non-existent methods' do
      allow(view_context).to receive(:respond_to?).with(:non_existent_method).and_return(false)

      expect {
        presenter.non_existent_method
      }.to raise_error(NoMethodError)
    end
  end

  describe '#respond_to_missing?' do
    it 'returns true for view_context methods' do
      allow(view_context).to receive(:respond_to?).with(:some_helper_method).and_return(true)

      expect(presenter.respond_to?(:some_helper_method)).to be true
    end

    it 'returns false for non-existent methods' do
      allow(view_context).to receive(:respond_to?).with(:non_existent_method).and_return(false)

      expect(presenter.respond_to?(:non_existent_method)).to be false
    end
  end
end

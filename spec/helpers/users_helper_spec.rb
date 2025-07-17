require 'rails_helper'

RSpec.describe UsersHelper, type: :helper do
  describe '#users_frame' do
    it '指定したタイトルキーで部分テンプレートを描画する' do
      allow(helper).to receive(:t).with('users.title').and_return('タイトル')
      expect(helper).to receive(:render).with('users/frame_layout', title: 'タイトル', testid: 'users-title-title')
      helper.users_frame('users.title') {}
    end
  end
end

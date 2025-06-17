require 'rails_helper'

RSpec.describe Authorization, type: :model do
  describe 'バリデーション' do
    it 'provider, uid, user があれば有効' do
      auth = build(:authorization)
      expect(auth).to be_valid
    end

    it 'provider がなければ無効' do
      auth = build(:authorization, provider: nil)
      expect(auth).not_to be_valid
      expect(auth.errors[:provider]).to be_present
    end

    it 'uid がなければ無効' do
      auth = build(:authorization, uid: nil)
      expect(auth).not_to be_valid
      expect(auth.errors[:uid]).to be_present
    end

    it 'user がなければ無効' do
      auth = build(:authorization, user: nil)
      expect(auth).not_to be_valid
      expect(auth.errors[:user]).to be_present
    end

    it '同じ provider, uid の組み合わせは一意でなければならない' do
      existing = create(:authorization, provider: 'github', uid: '123')
      dup = build(:authorization, provider: 'github', uid: '123')
      expect(dup).not_to be_valid
      expect(dup.errors[:uid]).to include('has already been taken')
    end
  end
end

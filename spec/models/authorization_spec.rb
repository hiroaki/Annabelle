require 'rails_helper'

RSpec.describe Authorization, type: :model do
describe 'Validations' do
    it 'does not allow duplicate provider/uid pair even for different users' do
      # provider, uid のペアはユーザーが違っても重複できない
      user1 = create(:user)
      user2 = create(:user)
      create(:authorization, user: user1, provider: 'github', uid: 'uid1')
      dup = build(:authorization, user: user2, provider: 'github', uid: 'uid1')
      expect(dup).not_to be_valid
      expect(dup.errors[:uid]).to include('has already been taken')
    end

    it 'allows same user and uid if provider is different' do
      # 同じユーザー・uidでもproviderが違えば登録できる
      user = create(:user)
      create(:authorization, user: user, provider: 'github', uid: 'uid1')
      auth = build(:authorization, user: user, provider: 'twitter', uid: 'uid1')
      expect(auth).to be_valid
    end

    it 'does not allow duplicate user/provider pair' do
      # 同じユーザー・providerの組み合わせは一意でなければならない
      user = create(:user)
      create(:authorization, user: user, provider: 'github', uid: 'uid1')
      dup = build(:authorization, user: user, provider: 'github', uid: 'uid2')
      expect(dup).not_to be_valid
      expect(dup.errors[:provider]).to include('has already been taken')
    end

    it 'is valid with provider, uid, and user' do
      auth = build(:authorization)
      expect(auth).to be_valid
    end

    it 'is invalid without provider' do
      auth = build(:authorization, provider: nil)
      expect(auth).not_to be_valid
      expect(auth.errors[:provider]).to be_present
    end

    it 'is invalid without uid' do
      auth = build(:authorization, uid: nil)
      expect(auth).not_to be_valid
      expect(auth.errors[:uid]).to be_present
    end

    it 'is invalid without user' do
      auth = build(:authorization, user: nil)
      expect(auth).not_to be_valid
      expect(auth.errors[:user]).to be_present
    end

    it 'does not allow duplicate provider/uid pair' do
      # provider, uid の組み合わせは一意でなければならない
      existing = create(:authorization, provider: 'github', uid: '123')
      dup = build(:authorization, provider: 'github', uid: '123')
      expect(dup).not_to be_valid
      expect(dup.errors[:uid]).to include('has already been taken')
    end
  end
end

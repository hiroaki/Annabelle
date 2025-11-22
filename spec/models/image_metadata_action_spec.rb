# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImageMetadataAction, type: :model do
  describe 'アソシエーション' do
    it 'user に属していること' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'バリデーション' do
    let(:user) { create(:user) }

    it '有効なレコードが作成できること' do
      action = described_class.new(
        user: user,
        blob_id: 'test_blob_id',
        action: 'upload',
        strip_metadata: true,
        allow_location_public: false
      )
      expect(action).to be_valid
    end

    it 'blob_id が必須であること' do
      action = described_class.new(
        user: user,
        action: 'upload',
        blob_id: nil
      )
      expect(action).not_to be_valid
      expect(action.errors[:blob_id]).to include("can't be blank")
    end

    it 'action が必須であること' do
      action = described_class.new(
        user: user,
        blob_id: 'test_blob_id',
        action: nil
      )
      expect(action).not_to be_valid
      expect(action.errors[:action]).to include("can't be blank")
    end

    it 'action が upload のみ許可されること' do
      action = described_class.new(
        user: user,
        blob_id: 'test_blob_id',
        action: 'invalid_action'
      )
      expect(action).not_to be_valid
      expect(action.errors[:action]).to include('is not included in the list')
    end
  end

  describe 'デフォルト値' do
    let(:user) { create(:user) }

    it 'strip_metadata のデフォルトが false であること' do
      action = described_class.new(user: user, blob_id: 'test')
      expect(action.strip_metadata).to be false
    end

    it 'allow_location_public のデフォルトが false であること' do
      action = described_class.new(user: user, blob_id: 'test')
      expect(action.allow_location_public).to be false
    end
  end
end

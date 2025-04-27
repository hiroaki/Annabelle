require 'rails_helper'

RSpec.describe Message, type: :model do
  describe "アソシエーション" do
    it "user に属していること" do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it "attachements を持っていること" do
      message = build(:message)
      expect(message).to respond_to(:attachements)
    end
  end

  describe "ファイルの添付" do
    it "ファイルを添付できること" do
      message = create(:message)
      file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'sample.txt'), 'text/plain')
      message.attachements.attach(file)
      expect(message.attachements.count).to eq(1)
    end
  end
end

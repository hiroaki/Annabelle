require 'rails_helper'

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:messages) }
  end

  describe "validations" do
    subject { build(:user) } # uniqueness をテストするので subject を指定

    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
    it { is_expected.to allow_value("valid_username123").for(:username) }
    it { is_expected.not_to allow_value("invalid username!").for(:username) }
  end

  describe ".generate_random_username" do
    context "when generated username is unique" do
      it "returns a unique username" do
        username = User.generate_random_username
        expect(username).to match(/\Auser_[a-z0-9]{8}\z/)
        expect(User.exists?(username: username)).to be_falsey
      end
    end

    context "when generated username conflicts" do
      it "retries until unique username is found" do
        taken_username = "user_abcdefgh"
        create(:user, username: taken_username)

        allow(SecureRandom).to receive(:alphanumeric).and_return("abcdefgh", "ijklmnop")

        username = User.generate_random_username
        expect(username).to eq("user_ijklmnop")
      end
    end

    context "when unique username cannot be generated after 10 tries" do
      it "raises an error" do
        allow(SecureRandom).to receive(:alphanumeric).and_return("abcdefgh")
        create(:user, username: "user_abcdefgh")

        expect {
          User.generate_random_username
        }.to raise_error("Unable to generate unique username")
      end
    end
  end

  describe ".from_omniauth" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "github",
        uid: "12345",
        info: OpenStruct.new(
          email: "user@example.com",
          nickname: "githubuser"
        )
      )
    end

    context "when user with provider and uid already exists" do
      let!(:existing_user) { create(:user, provider: "github", uid: "12345", email: "old@example.com", username: "oldname") }

      it "updates missing attributes if blank" do
        existing_user.update(email: nil, username: nil)
        user = User.from_omniauth(auth)

        expect(user).to eq(existing_user)
        expect(user.email).to eq("user@example.com")
        expect(user.username).to be_present
        expect(user.persisted?).to be_truthy
      end

      it "does not overwrite existing email and username if present" do
        user = User.from_omniauth(auth)

        expect(user.email).to eq("old@example.com")
        expect(user.username).to eq("oldname")
      end
    end

    context "when user with provider and uid does not exist" do
      context "and there is an unconfirmed user with same email" do
        let!(:unconfirmed_user) { create(:user, email: "user@example.com", confirmed_at: nil) }

        it "deletes the unconfirmed user and creates new one" do
          expect {
            User.from_omniauth(auth)
          }.to change(User, :count).by(0) # 1削除＋1作成

          expect(User.where(email: "user@example.com").count).to eq(1)
          user = User.find_by(provider: "github", uid: "12345")
          expect(user).to be_present
          expect(user.confirmed?).to be_truthy
        end
      end

      context "and there is a confirmed user with same email" do
        let!(:confirmed_user) { create(:user, email: "user@example.com", confirmed_at: Time.current) }

        it "does not delete confirmed user" do
          expect {
            User.from_omniauth(auth)
          }.not_to change(User, :count)

          expect(User.where(email: "user@example.com").count).to eq(1)
          user = User.find_by(email: "user@example.com")
          expect(user.provider).to eq("github")
          expect(user.uid).to eq("12345")
        end
      end

      context "and no existing user with same email" do
        it "creates a new user" do
          expect {
            User.from_omniauth(auth)
          }.to change(User, :count).by(1)

          user = User.last
          expect(user.email).to eq("user@example.com")
          expect(user.provider).to eq("github")
          expect(user.uid).to eq("12345")
          expect(user.confirmed?).to be_truthy
        end
      end
    end
  end

  describe "#transfer_messages_to_admin" do
    let(:user) { create(:user) }
    let!(:message1) { create(:message, user: user) }
    let!(:message2) { create(:message, user: user) }

    context "when admin user exists" do
      let!(:admin) { create(:user, email: 'admin@localhost', admin: true, confirmed_at: Time.current) }

      it "transfers all messages to the admin user" do
        expect {
          user.transfer_messages_to_admin
        }.to change { message1.reload.user_id }.from(user.id).to(admin.id)
         .and change { message2.reload.user_id }.from(user.id).to(admin.id)
      end
    end

    context "when admin user does not exist" do
      before do
        allow(Rails.logger).to receive(:warn)
      end

      it "does not raise an error and logs a warning" do
        expect {
          user.transfer_messages_to_admin
        }.not_to raise_error

        expect(Rails.logger).to have_received(:warn).with(/Admin user not found/)
      end
    end

    context "when user has no messages" do
      let(:user_without_messages) { create(:user) }
      let!(:admin) { create(:user, email: 'admin@localhost', admin: true, confirmed_at: Time.current) }

      it "does nothing and does not raise error" do
        expect {
          user_without_messages.transfer_messages_to_admin
        }.not_to raise_error
      end
    end
  end
end

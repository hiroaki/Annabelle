require 'rails_helper'
require 'ostruct'

RSpec.describe User, type: :model do
  describe "バリデーション" do
    context "ユーザー名について" do
      subject { build(:user) }

      context "存在性の確認" do
        it "ユーザー名が必須であること" do
          is_expected.to validate_presence_of(:username)
        end
      end

      context "一意性の確認（大文字小文字区別なし）" do
        it "重複しないユーザー名であること" do
          is_expected.to validate_uniqueness_of(:username).case_insensitive
        end
      end

      context "フォーマットの検証" do
        it "有効な形式のユーザー名なら許可されること" do
          is_expected.to allow_value("valid_username_123").for(:username)
        end

        it "無効な形式のユーザー名なら拒否されること" do
          is_expected.not_to allow_value("invalid username!").for(:username)
        end
      end
    end
  end

  describe ".generate_random_username! メソッド" do
    context "生成されたユーザー名がユニークな場合" do
      it "username が指定の正規表現にマッチすること" do
        username = described_class.generate_random_username!
        expect(username).to match(/\Auser_[a-z0-9]{8}\z/)
      end
    end

    context "衝突が発生する場合" do
      before do
        allow(SecureRandom).to receive(:alphanumeric).and_return("duplicate")
        create(:user, username: "user_duplicate")
      end

      it "10回の試行後にユニークな username を生成できず、エラーが発生すること" do
        expect { described_class.generate_random_username! }.to raise_error("Unable to generate unique username")
      end
    end
  end

  describe ".generate_random_password メソッド" do
    context "ランダムなパスワードが生成される場合" do
      it "生成されたパスワードが20文字であること" do
        password = described_class.generate_random_password
        expect(password.length).to eq(20)
      end
    end
  end

  describe ".from_omniauth メソッド" do
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

    context "対象ユーザーが存在しない場合" do
      it "新たに確認済みユーザーが作成され、Authorizationが生成されること" do
        expect {
          @user = described_class.from_omniauth(auth)
        }.to change { User.count }.by(1)

        expect(@user).to be_persisted
        expect(@user.email).to eq("user@example.com")
        expect(@user.username).to match(/\Auser_[a-z0-9]{8}\z/)
        expect(@user.confirmed?).to be true
        expect(@user.authorizations).to exist(provider: "github", uid: "12345")
      end
    end

    context "provider と uid に紐づく Authorization が既にある場合" do
      let!(:user_with_auth) { create(:user) }
      let!(:authorization) { create(:authorization, user: user_with_auth, provider: "github", uid: "12345") }

      it "そのユーザーを返すこと" do
        user = described_class.from_omniauth(auth)
        expect(user).to eq(user_with_auth)
      end
    end

    context "同じメールアドレスを持つ未確認ユーザーが存在する場合" do
      let!(:unconfirmed_user) { create(:user, email: "user@example.com", confirmed_at: nil) }

      it "未確認ユーザーが削除され、新たなユーザーが作成される" do
        expect {
          described_class.from_omniauth(auth)
        }.not_to change { User.count }

        user = User.find_by(email: "user@example.com")
        expect(user.authorizations).to exist(provider: "github", uid: "12345")
      end
    end

    context "同じメールアドレスを持つ確認済みユーザーが存在する場合" do
      let!(:confirmed_user) { create(:user, email: "user@example.com", confirmed_at: Time.current) }

      it "既存の確認済みユーザーを使って Authorization を作成する" do
        expect {
          described_class.from_omniauth(auth)
        }.to change { Authorization.count }.by(1)

        user = User.find_by(email: "user@example.com")
        expect(user).to eq(confirmed_user)
        expect(user.authorizations).to exist(provider: "github", uid: "12345")
      end
    end

    context "auth 情報に email が含まれない場合" do
      let(:auth_without_email) do
        OmniAuth::AuthHash.new(
          provider: "github",
          uid: "12345",
          info: OpenStruct.new(nickname: "githubuser")
        )
      end

      it "ユーザーは保存されないこと" do
        expect {
          user = described_class.from_omniauth(auth_without_email)
          expect(user).not_to be_persisted
        }.not_to change(User, :count)
      end
    end

    context "Authorization の作成に失敗する場合" do
      before do
        allow_any_instance_of(Authorization).to receive(:save).and_return(false)
      end

      it "ユーザーは保存されないこと" do
        expect {
          user = described_class.from_omniauth(auth)
          expect(user).not_to be_persisted
        }.not_to change(User, :count)
      end
    end
  end

  describe "#transfer_messages_to_admin インスタンスメソッド" do
    let!(:admin) { User.admin_user }
    let!(:user) { create(:user) }
    let!(:messages) { create_list(:message, 3, user: user) }

    context "管理者ユーザーが存在する場合" do
      it "ユーザー削除時に全メッセージが管理者に移管されること" do
        expect {
          user.destroy
        }.to change { messages.map { |msg| msg.reload.user_id } }.to(all(eq(admin.id)))
      end
    end

    context "管理者ユーザーが存在しない場合" do
      before do
        admin.destroy
      end

      it "ユーザー削除時に例外が発生すること" do
        expect {
          user.destroy
        }.to raise_error(RuntimeError, /Admin user not found\. Cannot transfer messages for user_id:/)
      end
    end
  end

  describe ".admin_user メソッド" do
    context "admin ユーザーが存在する場合" do
      it "admin ユーザーを返すこと" do
        admin = User.admin_user
        expect(admin).to be_present
        expect(admin.email).to eq('admin@localhost')
        expect(admin.admin).to be true
      end
    end

    context "admin ユーザーが存在しない場合" do
      it "nil を返すこと" do
        admin = User.admin_user
        admin.destroy

        expect(User.admin_user).to be_nil
      end
    end
  end

  describe "#link_with メソッド" do
    let!(:user) { create(:user) }

    it "Authorization を作成すること" do
      user.link_with('github', '12345')
      expect(user.authorizations).to exist(provider: 'github', uid: '12345')
    end
  end

  describe "#linked_with? メソッド" do
    let!(:user) { create(:user) }

    before do
      user.link_with('github', '12345')
    end

    it "provider に対応する Authorization がある場合 true を返す" do
      expect(user.linked_with?('github')).to be true
    end

    it "provider に対応する Authorization がない場合 false を返す" do
      expect(user.linked_with?('google')).to be false
    end
  end

  describe "#authorization_by_provider メソッド" do
    let(:user) { create(:user) }
    let!(:auth) { create(:authorization, user: user, provider: "github", uid: "12345") }

    it "指定した provider に紐づく Authorization を返すこと" do
      result = user.authorization_by_provider("github")
      expect(result).to eq(auth)
    end

    it "存在しない provider を指定した場合は nil を返すこと" do
      expect(user.authorization_by_provider("google")).to be_nil
    end
  end

  describe "#provider_uid メソッド" do
    let(:user) { create(:user) }
    let!(:auth) { create(:authorization, user: user, provider: "github", uid: "abc123") }

    it "指定した provider に紐づく uid を返すこと" do
      expect(user.provider_uid("github")).to eq("abc123")
    end

    it "指定した provider に紐づく Authorization が存在しない場合 nil を返すこと" do
      expect(user.provider_uid("google")).to be_nil
    end
  end
end

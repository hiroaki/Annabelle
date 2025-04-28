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

  describe ".generate_random_username メソッド" do
    context "生成されたユーザー名がユニークな場合" do
      it "username が指定の正規表現にマッチすること" do
        username = described_class.generate_random_username
        expect(username).to match(/\Auser_[a-z0-9]{8}\z/)
      end
    end

    context "衝突が発生する場合" do
      before do
        allow(SecureRandom).to receive(:alphanumeric).and_return("duplicate")
        create(:user, username: "user_duplicate")
      end

      it "10回の試行後にユニークな username を生成できず、エラーが発生すること" do
        expect { described_class.generate_random_username }.to raise_error("Unable to generate unique username")
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
      it "新たに確認済みユーザーが作成されること" do
        expect {
          @user = described_class.from_omniauth(auth)
        }.to change { User.count }.by(1)

        expect(@user).to be_persisted
        expect(@user.provider).to eq("github")
        expect(@user.uid).to eq("12345")
        expect(@user.email).to eq("user@example.com")
        expect(@user.username).to match(/\Auser_[a-z0-9]{8}\z/)
        expect(@user.confirmed?).to be true
      end
    end

    context "provider と uid で既存かつ、全属性が設定済みの場合" do
      let!(:existing_user) { create(:user, provider: "github", uid: "12345", email: "old@example.com", username: "oldname") }

      it "既存の email と username が上書きされないこと" do
        user = described_class.from_omniauth(auth)
        expect(user).to eq(existing_user)
        expect(user.email).to eq("old@example.com")
        expect(user.username).to eq("oldname")
      end
    end

    context "provider と uid で既存の場合" do
      let!(:existing_user) do
        create(:user, provider: "github", uid: "12345", email: "old@example.com", username: "existingusername")
      end

      it "既存ユーザのレコードが更新されず、そのまま返却されること" do
        user = described_class.from_omniauth(auth)
        expect(user).to eq(existing_user)
        expect(user.email).to eq("old@example.com")
        expect(user.username).to eq("existingusername")
      end
    end

    context "同じメールアドレスを持つ未確認ユーザーが存在する場合" do
      let!(:unconfirmed_user) { create(:user, email: "user@example.com", confirmed_at: nil) }

      it "未確認ユーザーが削除され、新たにユーザーが作成されること" do
        expect {
          described_class.from_omniauth(auth)
        }.to change { User.count }.by(0)  # 未確認ユーザーの削除と新規作成で件数は変化しない

        user = User.find_by(email: "user@example.com")
        expect(user.provider).to eq("github")
      end
    end

    context "同じメールアドレスを持つ確認済みユーザーが存在する場合" do
      let!(:confirmed_user) { create(:user, email: "user@example.com", confirmed_at: Time.current) }

      it "既存の確認済みユーザーがそのまま使用されること" do
        expect {
          described_class.from_omniauth(auth)
        }.to change { User.count }.by(0)

        user = User.find_by(email: "user@example.com")
        expect(user).to eq(confirmed_user)
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

    it "ユーザーの provider と uid を更新すること" do
      user.link_with('github', '12345')
      expect(user.provider).to eq('github')
      expect(user.uid).to eq('12345')
    end
  end

  describe "#linked_with? メソッド" do
    let!(:user) { create(:user, provider: 'github', uid: '12345') }

    it "provider と uid が一致する場合 true を返すこと" do
      expect(user.linked_with?('github')).to be true
    end

    it "provider または uid が一致しない場合 false を返すこと" do
      expect(user.linked_with?('google')).to be false
    end
  end
end

require 'rails_helper'

RSpec.describe "LocaleRedirect", type: :request do
  describe "GET /" do
    context "ルートパス (/) へのアクセス時" do
      it "適切なロケール付きURLにリダイレクトする" do
        get "/"
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to("/en")  # デフォルトロケールでリダイレクト
      end
    end

    context "Accept-Languageヘッダーが日本語の場合" do
      it "日本語ロケール付きURLにリダイレクトする" do
        get "/", headers: { "Accept-Language" => "ja,en;q=0.9" }
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to("/ja")
      end
    end

    context "セッションにロケールが保存されている場合" do
      it "現在のロケール決定ロジックに従ってリダイレクトする" do
        # まず言語切り替えでセッションに日本語を保存
        get "/locale/ja"

        # 現在のLocaleServiceではセッション確認がないため、デフォルトロケールになる
        # 再度ルートアクセス時は現在のロジックに従う（ここではデフォルト英語）
        get "/"
        expect(response).to have_http_status(:moved_permanently)
        # Note: 現在のロジックではセッション確認がないため英語にリダイレクト
        # これはステップ4（LocaleServiceロジック簡素化）で改善予定
        expect(response).to redirect_to("/en")
      end
    end

    context "クエリパラメータが含まれている場合" do
      it "クエリパラメータを保持したままリダイレクトする" do
        get "/?test=value"
        expect(response).to have_http_status(:moved_permanently)
        expect(response.location).to include("/en")
        expect(response.location).to include("test=value")
      end
    end
  end

  describe "明示的ロケール必須化の確認" do
    context "ロケール付きパスへのアクセス" do
      it "日本語ロケールパスが正常にルーティングされる" do
        get "/ja"
        # Deviseなどによるリダイレクトがあっても、ルーティングエラーでないことを確認
        expect(response).not_to have_http_status(:not_found)
        expect(response.status).to be_in([200, 302])
      end

      it "英語ロケールパスが正常にルーティングされる" do
        get "/en"
        # Deviseなどによるリダイレクトがあっても、ルーティングエラーでないことを確認
        expect(response).not_to have_http_status(:not_found)
        expect(response.status).to be_in([200, 302])
      end
    end

    context "無効なロケールパスへのアクセス" do
      it "ルーティングエラーが発生する" do
        # Railsのテスト環境では、開発モードとは異なりActionController::RoutingErrorが発生しない場合がある
        get "/invalid"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "OAuth特例処理の確認" do
    context "OAuthコールバックURL" do
      it "ロケールなしでもルーティング可能" do
        # OAuthコールバックはロケール必須化の例外
        get "/users/auth/github/callback"
        # ルーティングエラーでないことを確認（OAuth処理エラーは許容）
        expect(response).not_to have_http_status(:not_found)
      end

      it "OAuth認証パスもロケールなしでルーティング可能" do
        # POSTメソッドでOAuth認証を開始（通常の使用パターン）
        post "/users/auth/github"
        # OmniAuthプロバイダーへのリダイレクトまたは処理が発生
        expect(response).not_to have_http_status(:not_found)
      end
    end

    context "OAuth失敗パス" do
      it "失敗パスがロケールなしでルーティング可能" do
        get "/users/auth/failure"
        # 失敗処理が実行され、適切にリダイレクトされる
        expect(response).not_to have_http_status(:not_found)
        expect(response).to have_http_status(:redirect)
      end

      it "失敗時にI18n例外が発生しない" do
        # I18n補間エラーが修正されたことを確認
        expect {
          get "/users/auth/failure"
        }.not_to raise_error
      end
    end
  end
end

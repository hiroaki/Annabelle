require 'rails_helper'

RSpec.describe 'Messages proxy error', type: :system do
  def login_as(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'
  end

  before do
    user = FactoryBot.create(:user, :confirmed)
    login_as(user)
  end

  it 'shows flash message when proxy returns 413 error' do
    visit messages_path
    fill_in 'comment', with: 'テストメッセージ'

    # Cupriteのnetwork interceptで413エラーを返す
    page.driver.browser.network.intercept
    page.driver.browser.on(:request) do |request|
      puts "Intercepted: #{request.url} #{request.method}"
      if request.match?('/messages') && request.method == 'POST'
        puts "Returning 413 error for /messages POST"
        request.respond(
          responseCode: 413,
          responseHeaders: { "Content-Type" => "text/plain" },
          body: "Payload Too Large"
        )
      else
        puts "Continuing request: #{request.url}"
        request.continue
      end
    end

    # イベントのデバッグのためJavaScriptを追加
    page.execute_script(<<~JS)
      window.debugEvents = [];
      ['turbo:render', 'turbo:fetch-request-error', 'turbo:submit-end'].forEach(eventName => {
        document.addEventListener(eventName, function(event) {
          console.log('Event fired:', eventName, event.detail);
          
          // 安全にオブジェクトの構造を確認
          let detailInfo = {};
          if (event.detail) {
            detailInfo.hasFormSubmission = !!event.detail.formSubmission;
            detailInfo.hasFetchResponse = !!event.detail.fetchResponse;
            detailInfo.fetchResponseStatus = event.detail.fetchResponse?.status;
            detailInfo.eventDetailKeys = Object.keys(event.detail);
            
            // formSubmissionがある場合
            if (event.detail.formSubmission) {
              detailInfo.formSubmissionKeys = Object.keys(event.detail.formSubmission);
              detailInfo.formSubmissionResult = event.detail.formSubmission.result;
              
              // fetchResponseの詳細を確認
              if (event.detail.formSubmission.result && event.detail.formSubmission.result.fetchResponse) {
                const fetchResponse = event.detail.formSubmission.result.fetchResponse;
                detailInfo.fetchResponseKeys = Object.keys(fetchResponse);
                if (fetchResponse.response) {
                  detailInfo.responseKeys = Object.keys(fetchResponse.response);
                  detailInfo.responseStatus = fetchResponse.response.status;
                }
              }
            }
          }
          
          window.debugEvents.push({
            name: eventName, 
            detailInfo: detailInfo,
            hasFlashStorage: !!document.getElementById('flash-storage')?.querySelector('ul')?.children?.length
          });
        });
      });
    JS

    click_button I18n.t('messages.form.post')

    # イベントの発火状況を確認
    sleep 1 # イベント処理の完了を待つ
    events = page.evaluate_script('window.debugEvents')
    puts "Fired events: #{events.inspect}"

    # flashメッセージが表示されることを確認
    # TODO: 実際のメッセージに合わせて修正
    expect(page).to have_content('ファイルサイズが大きすぎます')
  end
end

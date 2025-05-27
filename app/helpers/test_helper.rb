module TestHelper
  # Capybara でテストする際に、要素を特定するための data 属性をつけるためのヘルパーです。
  # data-testid="testid" を付与します。ただし本番環境では何も付与しません。
  # 適用する要素に他の data 属性もつける場合はそれらを options として渡してください。
  #
  # なお "data-testid" 属性自体の名称を変更する場合は Capybara の設定も併せて修正が必要です。
  #
  # 使用例：
  # <%= content_tag :div, message, class: "container", **data_with_testid('flash-message', controller: 'dismissable') %>
  #
  # 使用例（ブロック）：
  # <%= data_with_testid('login-button') do |opts| %>
  #   <%= link_to 'Login', login_path, opts %>
  # <% end %>
  def data_with_testid(testid, extra = {})
    options = {}

    if Rails.env.production?
      options[:data] = extra
    else
      options[:data] = extra.dup
      options[:data][:testid] = testid
    end

    if block_given?
      yield(options)
    else
      options
    end
  end
end

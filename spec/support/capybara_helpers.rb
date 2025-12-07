module CapybaraHelpers
  # test_id の要素を取得
  def find_testid(id, **options)
    find("[#{key}='#{id}']", **options)
  end

  # test_id の要素を複数取得
  def all_testid(id, **options)
    all("[#{key}='#{id}']", **options)
  end

  # ブラウザウィンドウのサイズを変更
  # レスポンシブデザインのテストに使用
  def resize_window(width, height)
    page.current_window.resize_to(width, height)
  end

  # よく使うデバイスサイズのプリセット
  WINDOW_SIZES = {
    desktop: [1200, 800],
    tablet: [768, 1024],
    mobile: [375, 667],    # iPhone SE
    mobile_small: [320, 568] # iPhone 5/SE (old)
  }.freeze

  def resize_to(device)
    width, height = WINDOW_SIZES[device]
    raise ArgumentError, "Unknown device: #{device}" unless width

    resize_window(width, height)
  end

  private

  def key
    Capybara.test_id
  end
end

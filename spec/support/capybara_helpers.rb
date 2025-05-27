module CapybaraHelpers
  # test_id の要素を取得
  def find_testid(id, **options)
    find("[#{key}='#{id}']", **options)
  end

  # test_id の要素を複数取得
  def all_testid(id, **options)
    all("[#{key}='#{id}']", **options)
  end

  private

  def key
    Capybara.test_id
  end
end

module UsersHelper
  def users_frame(title_key, &block)
    title = t(title_key)
    testid = [title_key.gsub('.', '-'), 'title'].join('-')
    render 'users/frame_layout', title: title, testid: testid, &block
  end
end

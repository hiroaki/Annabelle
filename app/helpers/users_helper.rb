module UsersHelper
  def users_frame(title_key, &block)
    render 'users/frame_layout', title: t(title_key), &block
  end
end

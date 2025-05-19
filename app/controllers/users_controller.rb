class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  # user GET /users/:id(.:format)
  def show
  end

  # edit_user GET /users/:id/edit(.:format)
  def edit
  end

  # PATCH /users/:id(.:format)
  # PUT /users/:id(.:format)
  def update
    if @user.update(user_params_for_profile)
      flash.now[:notice] = "success"
      respond_to do |format|
        format.turbo_stream
      end
    else
      flash.now[:alert] = "failure"
      render :edit
    end
  end

  # two_factor_authentication_user GET /users/:id/two_factor_authentication(.:format)
  def two_factor_authentication
  end

  private

  def set_user
    @user = current_user
  end

  def user_params_for_profile
    params.require(:user).permit(:username)
  end
end

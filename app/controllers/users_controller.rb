class UsersController < ApplicationController
  before_action :authenticate_user!

  # user GET /users/:id(.:format)
  def show
    @user = current_user
  end

  # edit_user GET /users/:id/edit(.:format)
  def edit
    @user = current_user
  end

  # PATCH /users/:id(.:format)
  # PUT /users/:id(.:format)
  def update
    @user = current_user
    render 'show'
  end

  # two_factor_authentication_user GET /users/:id/two_factor_authentication(.:format)
  def two_factor_authentication
    @user = current_user
  end
end

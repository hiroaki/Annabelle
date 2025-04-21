class CreateSuperUser < ActiveRecord::Migration[8.0]
  def up
    User.create!(
      email: 'admin@localhost',
      password: 'YOU MUST CHANGE THIS',
      password_confirmation: 'YOU MUST CHANGE THIS',
      admin: true,
    )
  end

  def down
    User.find_by(email: 'admin@localhost', admin: true)&.destroy
  end
end

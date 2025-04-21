class AddUserToMessages < ActiveRecord::Migration[8.0]
  def up
    # user_id カラムを追加（既存のレコードのために、最初は null 許可）
    add_reference :messages, :user, foreign_key: true, null: true

    # admin ユーザの ID を取得して既存レコードにセット
    admin = User.find_by(admin: true)
    raise "Admin user not found" unless admin

    Message.reset_column_information
    Message.where(user_id: nil).update_all(user_id: admin.id)

    # すべてのメッセージに user_id が設定されたあとに null 制約を加える
    change_column_null :messages, :user_id, false
  end

  def down
    remove_reference :messages, :user, foreign_key: true
  end
end

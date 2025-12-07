# Rails の起動プロセス外（例: 軽量な rake タスクや単体スクリプト）で利用される場合に備え、
# 明示的に ActiveModel::Type::Boolean を require しています。
# Ruby の require は二重読み込みを防止するため、Rails アプリ内での利用時に副作用はありません。
require 'active_model/type/boolean'

# 文字列を真偽値として判定するヘルパーを提供するモジュールです。
# 真偽値の定義は ActiveModel::Type::Boolean に委ねられます。
module StringBoolean
  # ActiveModel::Type::Boolean のインスタンスを使い回すことでパフォーマンスを向上させます。
  BOOLEAN_TYPE = ActiveModel::Type::Boolean.new.freeze

  # val を BOOLEAN_TYPE.cast に与え、その結果を返します。
  # ただし結果が nil であった場合は default に指定した値を返します。
  def self.truthy?(val, default: false)
    result = BOOLEAN_TYPE.cast(val)
    result.nil? ? default : result
  end

  # val を BOOLEAN_TYPE.cast に与え、その結果を反転して返します。
  # ただし結果が nil であった場合は default に指定した値を返します。
  def self.falsey?(val, default: true)
    result = BOOLEAN_TYPE.cast(val)
    result.nil? ? default : !result
  end
end

class JsonStringArrayType < ActiveRecord::Type::Value
  def cast(value)
    case value
    when String
      JSON.parse(value).map(&:to_s)
    when Array
      value.map(&:to_s)
    else
      []
    end
  rescue JSON::ParserError
    []
  end

  def serialize(value)
    Array(value).map(&:to_s).to_json
  end
end

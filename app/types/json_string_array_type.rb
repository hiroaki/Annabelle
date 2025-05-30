class JsonStringArrayType < ActiveRecord::Type::Value
  def cast(value)
    case value
    when String
      parsed = JSON.parse(value)
      unless parsed.is_a?(Array)
        raise TypeError, "Expected JSON array, got #{parsed.class}"
      end
      parsed.map(&:to_s)
    when Array
      value.map(&:to_s)
    when nil
      []
    else
      raise TypeError, "Unsupported type for JsonStringArrayType: #{value.class}"
    end
  rescue JSON::ParserError
    []
  end

  def serialize(value)
    Array(value).map(&:to_s).to_json
  end
end

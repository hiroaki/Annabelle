require 'rails_helper'

RSpec.describe JsonStringArrayType do
  subject(:type) { described_class.new }

  describe '#cast' do
    context 'when value is a JSON string representing an array of strings' do
      let(:value) { '["foo", "bar", "baz"]' }

      it 'parses the JSON and returns an array of strings' do
        expect(type.cast(value)).to eq(['foo', 'bar', 'baz'])
      end
    end

    context 'when value is a JSON string representing an array of numbers' do
      let(:value) { '[1, 2, 3]' }

      it 'parses the JSON and returns an array of strings' do
        expect(type.cast(value)).to eq(['1', '2', '3'])
      end
    end

    context 'when value is a JSON string but not an array' do
      let(:value) { '"not an array"' }

      it 'raises TypeError' do
        expect { type.cast(value) }.to raise_error(TypeError, /Expected JSON array/)
      end
    end

    context 'when value is an Array of strings' do
      let(:value) { ['foo', 'bar'] }

      it 'returns the array as strings' do
        expect(type.cast(value)).to eq(['foo', 'bar'])
      end
    end

    context 'when value is an Array of numbers' do
      let(:value) { [1, 2, 3] }

      it 'returns the array as strings' do
        expect(type.cast(value)).to eq(['1', '2', '3'])
      end
    end

    context 'when value is nil' do
      let(:value) { nil }

      it 'returns an empty array' do
        expect(type.cast(value)).to eq([])
      end
    end

    context 'when value is an unsupported type (e.g. Hash)' do
      let(:value) { { foo: 'bar' } }

      it 'raises TypeError' do
        expect { type.cast(value) }.to raise_error(TypeError, /Unsupported type/)
      end
    end

    context 'when value is a malformed JSON string' do
      let(:value) { '["foo", "bar"' } # missing closing bracket

      it 'rescues JSON::ParserError and returns []' do
        expect(type.cast(value)).to eq([])
      end
    end

    context 'when value is an unsupported type (e.g. Integer)' do
      let(:value) { 123 }

      it 'raises TypeError' do
        expect { type.cast(value) }.to raise_error(TypeError, /Unsupported type/)
      end
    end
  end

  describe '#serialize' do
    context 'when value is an array of strings' do
      let(:value) { ['foo', 'bar'] }

      it 'returns a JSON string of the array' do
        expect(type.serialize(value)).to eq('["foo","bar"]')
      end
    end

    context 'when value is an array of numbers' do
      let(:value) { [1, 2, 3] }

      it 'returns a JSON string of the array as strings' do
        expect(type.serialize(value)).to eq('["1","2","3"]')
      end
    end

    context 'when value is nil' do
      let(:value) { nil }

      it 'returns a JSON string of an empty array' do
        expect(type.serialize(value)).to eq('[]')
      end
    end

    context 'when value is a single string' do
      let(:value) { 'foo' }

      it 'returns a JSON string of an array with one string' do
        expect(type.serialize(value)).to eq('["foo"]')
      end
    end

    context 'when value is a single number' do
      let(:value) { 123 }

      it 'returns a JSON string of an array with one string' do
        expect(type.serialize(value)).to eq('["123"]')
      end
    end
  end
end


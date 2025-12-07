require 'rails_helper'
require 'string_boolean'

RSpec.describe StringBoolean do
  describe '.truthy?' do
    it 'returns true for values ActiveModel::Type::Boolean treats as true' do
      expect(described_class.truthy?('1')).to be true
      expect(described_class.truthy?('true')).to be true
      expect(described_class.truthy?('yes')).to be true # yes is true
      expect(described_class.truthy?('on')).to be true
      expect(described_class.truthy?('no')).to be true  # no is true
      expect(described_class.truthy?('random')).to be true
    end

    it 'returns false for values ActiveModel::Type::Boolean treats as false' do
      expect(described_class.truthy?('0')).to be false
      expect(described_class.truthy?('false')).to be false
      expect(described_class.truthy?('off')).to be false
      expect(described_class.truthy?(nil)).to be false
      expect(described_class.truthy?('')).to be false
    end

    it 'returns default only if value is nil' do
      expect(described_class.truthy?(nil, default: true)).to be true
      expect(described_class.truthy?(nil, default: false)).to be false
      # non-nil values always follow ActiveModel::Type::Boolean result
      expect(described_class.truthy?('0', default: true)).to be false
      expect(described_class.truthy?('off', default: true)).to be false
      expect(described_class.truthy?('0', default: false)).to be false
      expect(described_class.truthy?('off', default: false)).to be false
    end
  end

  describe '.falsey?' do
    it 'returns true for values ActiveModel::Type::Boolean treats as false' do
      expect(described_class.falsey?('0')).to be true
      expect(described_class.falsey?('false')).to be true
      expect(described_class.falsey?('off')).to be true
      expect(described_class.falsey?('')).to be true
    end

    it 'returns default only if value is nil' do
      expect(described_class.falsey?(nil, default: true)).to be true
      expect(described_class.falsey?(nil, default: false)).to be false
    end

    it 'returns false for values ActiveModel::Type::Boolean treats as true' do
      expect(described_class.falsey?('1')).to be false
      expect(described_class.falsey?('true')).to be false
      expect(described_class.falsey?('yes')).to be false
      expect(described_class.falsey?('on')).to be false
      expect(described_class.falsey?('no')).to be false
      expect(described_class.falsey?('random')).to be false
    end

    it 'ignores default when value is non-nil, following ActiveModel::Type::Boolean result' do
      expect(described_class.falsey?('1', default: false)).to be false
      expect(described_class.falsey?('0', default: false)).to be true
      expect(described_class.falsey?('off', default: false)).to be true
      expect(described_class.falsey?('1', default: true)).to be false
      expect(described_class.falsey?('0', default: true)).to be true
      expect(described_class.falsey?('off', default: true)).to be true
    end
  end
end

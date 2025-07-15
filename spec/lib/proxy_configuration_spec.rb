require 'rails_helper'

RSpec.describe ProxyConfiguration do
  let(:instance) { described_class.instance }

  describe '.request_size_limit' do
    it 'returns a default value' do
      expect(described_class.request_size_limit).to be_a(Integer)
      expect(described_class.request_size_limit).to be > 0
    end
  end

  describe '.show_limits?' do
    it 'returns a boolean value' do
      expect([true, false]).to include(described_class.show_limits?)
    end
  end

  describe '.formatted_limit' do
    it 'returns a formatted string with units' do
      formatted = described_class.formatted_limit
      expect(formatted).to be_a(String)
      expect(formatted).to match(/\d+(\.\d+)?\s*(bytes|KB|MB|GB)/)
    end
  end

  describe '#parse_size' do
    let(:config) { instance }

    it 'parses gigabyte values correctly' do
      expect(config.send(:parse_size, '1GB')).to eq(1.gigabyte)
      expect(config.send(:parse_size, '1.5gb')).to eq((1.5 * 1.gigabyte).to_i)
    end

    it 'parses megabyte values correctly' do
      expect(config.send(:parse_size, '100MB')).to eq(100.megabytes)
      expect(config.send(:parse_size, '50mb')).to eq(50.megabytes)
    end

    it 'parses kilobyte values correctly' do
      expect(config.send(:parse_size, '500KB')).to eq(500.kilobytes)
      expect(config.send(:parse_size, '1kb')).to eq(1.kilobyte)
    end

    it 'parses byte values correctly' do
      expect(config.send(:parse_size, '1024')).to eq(1024)
      expect(config.send(:parse_size, '2048 bytes')).to eq(2048)
    end

    it 'returns default for invalid input' do
      expect(config.send(:parse_size, 'invalid')).to eq(ProxyConfiguration::DEFAULT_REQUEST_SIZE_LIMIT)
    end
  end
end
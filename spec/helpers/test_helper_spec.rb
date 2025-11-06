require 'rails_helper'

RSpec.describe TestHelper, type: :helper do
  describe '#data_with_testid' do
    let(:testid) { 'sample-test-id' }
    let(:extra_options) { { class: 'sample-class', id: 'sample-id' } }

    context 'in non-production environment' do
      before do
        allow(Rails).to receive(:env).and_return(double(production?: false))
      end

      context 'without extra options' do
        it 'returns hash with testid in data attribute' do
          result = helper.data_with_testid(testid)

          expect(result).to eq({
            data: { testid: testid }
          })
        end
      end

      context 'with extra options' do
        it 'merges extra options with testid in data attribute' do
          result = helper.data_with_testid(testid, extra_options)

          expect(result).to eq({
            data: extra_options.merge(testid: testid)
          })
        end

        it 'does not modify original extra options hash' do
          original_extra = extra_options.dup
          helper.data_with_testid(testid, extra_options)

          expect(extra_options).to eq(original_extra)
        end
      end

      context 'when extra options contain data key' do
        let(:extra_with_data) { { data: { turbo_method: :delete }, class: 'sample' } }

        it 'includes all extra options with testid added' do
          result = helper.data_with_testid(testid, extra_with_data)

          expect(result).to eq({
            data: { data: { turbo_method: :delete }, class: 'sample', testid: testid }
          })
        end
      end

      context 'with block given' do
        it 'yields the options hash to block' do
          yielded_options = nil

          helper.data_with_testid(testid, extra_options) do |options|
            yielded_options = options
          end

          expect(yielded_options).to eq({
            data: extra_options.merge(testid: testid)
          })
        end

        it 'returns the result of the block' do
          result = helper.data_with_testid(testid) do |options|
            "Block result with #{options[:data][:testid]}"
          end

          expect(result).to eq("Block result with #{testid}")
        end
      end
    end

    context 'in production environment' do
      before do
        allow(Rails).to receive(:env).and_return(double(production?: true))
      end

      context 'without extra options' do
        it 'returns hash with empty data attribute' do
          result = helper.data_with_testid(testid)

          expect(result).to eq({
            data: {}
          })
        end
      end

      context 'with extra options' do
        it 'returns extra options without testid' do
          result = helper.data_with_testid(testid, extra_options)

          expect(result).to eq({
            data: extra_options
          })
        end

        it 'does not modify original extra options hash' do
          original_extra = extra_options.dup
          helper.data_with_testid(testid, extra_options)

          expect(extra_options).to eq(original_extra)
        end
      end

      context 'when extra options contain data key' do
        let(:extra_with_data) { { data: { turbo_method: :delete }, class: 'sample' } }

        it 'includes all extra options without testid' do
          result = helper.data_with_testid(testid, extra_with_data)

          expect(result).to eq({
            data: { data: { turbo_method: :delete }, class: 'sample' }
          })
        end
      end

      context 'with block given' do
        it 'yields the options hash without testid to block' do
          yielded_options = nil

          helper.data_with_testid(testid, extra_options) do |options|
            yielded_options = options
          end

          expect(yielded_options).to eq({
            data: extra_options
          })
        end

        it 'returns the result of the block' do
          result = helper.data_with_testid(testid) do |options|
            "Production block result"
          end

          expect(result).to eq("Production block result")
        end
      end
    end

    context 'edge cases' do
      before do
        allow(Rails).to receive(:env).and_return(double(production?: false))
      end

      context 'when testid is nil' do
        it 'handles nil testid gracefully' do
          result = helper.data_with_testid(nil)

          expect(result).to eq({
            data: { testid: nil }
          })
        end
      end

      context 'when testid is empty string' do
        it 'handles empty testid' do
          result = helper.data_with_testid('')

          expect(result).to eq({
            data: { testid: '' }
          })
        end
      end

      context 'when extra is nil' do
        it 'handles nil extra options' do
          expect {
            helper.data_with_testid(testid, nil)
          }.to raise_error(NoMethodError)
        end
      end

      context 'when extra contains nested data structures' do
        let(:complex_extra) { { data: { nested: { deep: 'value' } }, other: 'option' } }

        it 'handles complex data structures' do
          result = helper.data_with_testid(testid, complex_extra)

          expect(result).to eq({
            data: { data: { nested: { deep: 'value' } }, other: 'option', testid: testid }
          })
        end
      end
    end

    # Rails環境の動作確認用のテスト
    describe 'Rails environment detection' do
      it 'correctly detects development environment' do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))

        result = helper.data_with_testid(testid)
        expect(result[:data]).to have_key(:testid)
      end

      it 'correctly detects test environment' do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('test'))

        result = helper.data_with_testid(testid)
        expect(result[:data]).to have_key(:testid)
      end

      it 'correctly detects production environment' do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))

        result = helper.data_with_testid(testid)
        expect(result[:data]).not_to have_key(:testid)
      end
    end
  end
end

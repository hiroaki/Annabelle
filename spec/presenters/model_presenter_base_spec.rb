require 'rails_helper'

class DummyViewContext < ActionView::Base
  def self.with_empty_template
    # Use a temporary directory as view path to satisfy ActionView::Base
    tmp_dir = Dir.mktmpdir
    result = self.with_view_paths(tmp_dir)
    result.is_a?(Class) ? result.new : result
  end

  def helper_method_example(arg)
    "helper: #{arg}"
  end
end

class DummyModel
  attr_reader :value
  def initialize(value)
    @value = value
  end
end

RSpec.describe ModelPresenterBase do
  let(:view_context) { DummyViewContext.with_empty_template }
  let(:model) { DummyModel.new('foo') }
  let(:presenter) { described_class.new(view_context, model) }

  describe '#initialize' do
    it 'sets view_context and model' do
      expect(presenter.view_context).to eq(view_context)
      expect(presenter.model).to eq(model)
    end

    it 'raises if view_context is not ActionView::Base' do
      expect {
        described_class.new(Object.new, model)
      }.to raise_error(ArgumentError)
    end

    it 'yields self if block given' do
      yielded = nil
      described_class.new(view_context, model) { |p| yielded = p }
      expect(yielded).to be_a(described_class)
    end
  end

  describe '#method_missing' do
    it 'delegates to view_context if method exists' do
      expect(presenter.helper_method_example('bar')).to eq('helper: bar')
    end

    it 'raises NoMethodError if method not found' do
      expect { presenter.unknown_method }.to raise_error(NoMethodError)
    end
  end

  describe '#respond_to_missing?' do
    it 'returns true if view_context responds to method' do
      expect(presenter.respond_to?(:helper_method_example)).to be true
    end
    it 'returns false if neither view_context nor super responds' do
      expect(presenter.respond_to?(:not_a_method)).to be false
    end
  end

  describe '.build' do
    it 'returns an enumerator if no block given' do
      enum = described_class.build(view_context, [model])
      expect(enum).to be_an(Enumerator)
      expect(enum.to_a.first).to be_a(described_class)
    end

    it 'yields presenters for each model if block given' do
      models = [DummyModel.new('a'), DummyModel.new('b')]
      yielded = []
      described_class.build(view_context, models) { |p| yielded << p.model.value }
      expect(yielded).to eq(['a', 'b'])
    end
  end
end

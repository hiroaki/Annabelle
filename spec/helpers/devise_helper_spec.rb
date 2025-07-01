require 'rails_helper'

RSpec.describe DeviseHelper, type: :helper do
  class DummyResource; end
  DummyMapping = Struct.new(:singular)

  describe '#devise_path_for' do
    it 'returns nil when helper method does not exist' do
      dummy = DummyResource.new
      allow(Devise).to receive(:mappings).and_return({ dummy_resource: DummyMapping.new('dummy_resource') })
      expect(helper.devise_path_for('nonexistent', dummy)).to be_nil
    end

    it 'calls the helper method when it exists' do
      dummy = DummyResource.new
      allow(Devise).to receive(:mappings).and_return({ dummy_resource: DummyMapping.new('dummy_resource') })
      def helper.edit_dummy_resource_registration_path; '/dummy/edit'; end
      expect(helper.devise_path_for('edit', dummy)).to eq('/dummy/edit')
    end
  end
end

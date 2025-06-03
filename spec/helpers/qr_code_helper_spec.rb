require 'rails_helper'

RSpec.describe QrCodeHelper, type: :helper do
  describe '#qr_code_as_svg' do
    it 'SVG文字列を返す' do
      svg = helper.qr_code_as_svg('https://example.com')
      expect(svg).to include('<svg')
      expect(svg).to include('crispEdges')
      expect(svg).to include('standalone')
    end
  end
end

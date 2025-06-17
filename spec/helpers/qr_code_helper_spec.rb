require 'rails_helper'

RSpec.describe QrCodeHelper, type: :helper do
  describe '#qr_code_as_svg' do
    it 'SVG文字列を返す' do
      svg = helper.qr_code_as_svg('https://example.com')
      expect(svg).to include('<svg')
      expect(svg).to include('crispEdges')
      expect(svg).to include('standalone')
    end

    it 'nilを渡した場合はArgumentErrorになる' do
      expect { helper.qr_code_as_svg(nil) }.to raise_error(ArgumentError)
    end

    it '空文字を渡した場合はArgumentErrorになる' do
      expect { helper.qr_code_as_svg('') }.to raise_error(ArgumentError)
    end

    it '不正な値を渡した場合もエラーにならずSVGを返す' do
      svg = helper.qr_code_as_svg('!!!')
      expect(svg).to include('<svg')
    end
  end
end

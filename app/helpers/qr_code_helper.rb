module QrCodeHelper
  def qr_code_as_svg(uri)
    raise ArgumentError, 'uri must not be blank' if uri.blank?

    RQRCode::QRCode.new(uri).as_svg(
      offset: 0,
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 4,
      standalone: true
    ).html_safe
  end
end

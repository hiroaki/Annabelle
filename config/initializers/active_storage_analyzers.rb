# Ensure custom Active Storage analyzers are registered. We keep this in an
# initializer so it runs after Rails loads the default analyzers and so
# config.to_prepare re-applies the ordering on reload; wiring it in
# config/application.rb would have to replicate that lifecycle handling.
require Rails.root.join('app/analyzers/active_storage/analyzer/exif_analyzer')

Rails.application.config.to_prepare do
  analyzers = Rails.application.config.active_storage.analyzers
  analyzers.delete(ActiveStorage::Analyzer::ExifAnalyzer)
  analyzers.unshift(ActiveStorage::Analyzer::ExifAnalyzer)
end

# Run using bin/ci

CI.run do
  step "Setup: Local test prerequisites", <<~SH
    bundle check || bundle install
    env RAILS_ENV=test bin/rails db:prepare
  SH

  step "Style: RuboCop", "bin/rubocop"
  step "Security: Brakeman", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Tests: RSpec(1/2)", "bin/rspec"
  step "Tests: RSpec(2/2)", "env RSPEC_DISABLE_OAUTH_GITHUB=1 bin/rspec spec/system/oauth_github_disabled/"

  step "Docker: Build and boot staging image", <<~SH
    docker build --target runtime \
      --build-arg RAILS_ENV=staging \
      --build-arg BUNDLE_WITHOUT=development:test \
      --build-arg PRECOMPILE_ASSETS=1 \
      -t annabelle-staging-check .
    docker run --rm \
      -e RAILS_ENV=staging \
      -e SECRET_KEY_BASE_DUMMY=1 \
      -e DOCKER=1 \
      -e ANNABELLE_VARIANT_PROCESSOR=vips \
      --entrypoint bin/rails \
      annabelle-staging-check \
      runner 'Rails.application.eager_load!; puts :ok'
  SH
end

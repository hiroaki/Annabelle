# Run using bin/ci

CI.run do
  step "Setup: Local prerequisites", <<~SH
    set -eu
    bundle check || bundle install
  SH

  step "Style: RuboCop", "bin/rubocop"
  step "Security: Brakeman", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"

  step "Docker: Build and test runtime-test image", <<~SH
    set -eu

    IMAGE_NAME=annabelle-runtime-test-check:latest
    CONTAINER_NAME=annabelle-runtime-test-check

    export ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY="$(openssl rand -hex 32)"
    export ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY="$(openssl rand -hex 32)"
    export ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT="$(openssl rand -hex 32)"

    docker build \
      --target runtime-test \
      --build-arg RAILS_ENV=test \
      --build-arg BUNDLE_WITHOUT=development \
      --build-arg PRECOMPILE_ASSETS=1 \
      --tag "$IMAGE_NAME" \
      .

    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    trap 'docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true' EXIT

    docker run --name "$CONTAINER_NAME" \
      -e DOCKER=1 \
      -e RAILS_ENV=test \
      -e ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY \
      -e ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY \
      -e ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT \
      "$IMAGE_NAME" \
      bash -lc '
        set -eu
        bin/rails db:prepare
        bundle exec rspec
        RSPEC_DISABLE_OAUTH_GITHUB=1 bin/rspec spec/system/oauth_github_disabled/
        test -f /rails/coverage/lcov.info
      '
  SH

  step "Docker: Build and boot staging image", <<~SH
    set -eu

    IMAGE_NAME=annabelle-staging-check:latest

    docker build --target runtime \
      --build-arg RAILS_ENV=staging \
      --build-arg BUNDLE_WITHOUT=development:test \
      --build-arg PRECOMPILE_ASSETS=1 \
      --tag "$IMAGE_NAME" \
      .

    docker run --rm \
      -e RAILS_ENV=staging \
      -e SECRET_KEY_BASE_DUMMY=1 \
      -e DOCKER=1 \
      -e ANNABELLE_VARIANT_PROCESSOR=vips \
      -e ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY \
      -e ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY \
      -e ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT \
      --entrypoint bin/rails \
      "$IMAGE_NAME" \
      runner "Rails.application.eager_load!; puts :ok"
  SH
end
## Build examples
# production
#   docker build \
#     --target runtime \
#     --build-arg RAILS_ENV=production \
#     --build-arg BUNDLE_WITHOUT=development:test \
#     --build-arg PRECOMPILE_ASSETS=1 \
#     -t annabelle-production:latest .
#
# staging
#   docker build \
#     --target runtime \
#     --build-arg RAILS_ENV=staging \
#     --build-arg BUNDLE_WITHOUT=development:test \
#     --build-arg PRECOMPILE_ASSETS=1 \
#     -t annabelle-staging:latest .
#
# test (CI)
#   docker build \
#     --target runtime-test \
#     --build-arg RAILS_ENV=test \
#     --build-arg BUNDLE_WITHOUT=development \
#     --build-arg PRECOMPILE_ASSETS=1 \
#     -t annabelle-test:latest .
#
# development
#   docker build \
#     --target runtime-dev \
#     --build-arg RAILS_ENV=development \
#     --build-arg BUNDLE_WITHOUT= \
#     --build-arg PRECOMPILE_ASSETS=0 \
#     -t annabelle-development:latest .

ARG RUBY_VERSION=3.4.10
ARG BUNDLER_VERSION=4.0.8
ARG RAILS_ENV=production
ARG BUNDLE_WITHOUT=""
ARG PRECOMPILE_ASSETS=0
ARG THRUSTER_HTTP_PORT=3001
ARG THRUSTER_TARGET_PORT=3000

FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim-bookworm AS base

ARG BUNDLER_VERSION
ARG RAILS_ENV
ARG THRUSTER_HTTP_PORT
ARG THRUSTER_TARGET_PORT

RUN gem install bundler -v "$BUNDLER_VERSION"

WORKDIR /rails

ENV BUNDLE_PATH="/usr/local/bundle" \
    RAILS_ENV=$RAILS_ENV \
    THRUSTER_HTTP_PORT=${THRUSTER_HTTP_PORT} \
    THRUSTER_TARGET_PORT=${THRUSTER_TARGET_PORT} \
    THRUSTER_DEBUG=1 \
    PORT=${THRUSTER_TARGET_PORT}

FROM base AS build-base

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    build-essential \
    libvips \
    libsqlite3-dev \
    libyaml-dev \
    pkg-config \
    tzdata \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

FROM build-base AS build

ARG BUNDLE_WITHOUT
ARG PRECOMPILE_ASSETS

COPY Gemfile Gemfile.lock ./

# Keep Bundler configuration on disk because bootsnap precompile expects .bundle/config.
RUN if [ -n "$BUNDLE_WITHOUT" ]; then \
      bundle config set --local without "$BUNDLE_WITHOUT"; \
      bundle config set --local deployment true; \
    else \
      bundle config unset --local without || true; \
      bundle config unset --local deployment || true; \
    fi \
  && bundle install \
  && rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

RUN bundle exec bootsnap precompile -j 0 --gemfile app/ lib/ config/

RUN if [ "$PRECOMPILE_ASSETS" = "1" ]; then \
      SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile; \
    else \
      echo "Skip assets:precompile"; \
    fi

FROM base AS runtime-base

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    curl \
    ffmpeg \
    libsqlite3-0 \
    libvips \
    imagemagick \
    tzdata \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --from=build /rails /rails
COPY --from=build /usr/local/bundle /usr/local/bundle

RUN useradd rails --create-home --shell /bin/bash \
  && mkdir -p /rails/db /rails/log /rails/storage /rails/tmp /usr/local/bundle \
  && chown -R rails:rails /rails /usr/local/bundle

FROM runtime-base AS runtime

USER rails:rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE ${PORT}
CMD ["bundle", "exec", "thrust", "bin/rails", "server"]

FROM runtime AS runtime-test

USER root

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    chromium \
    fonts-liberation \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    procps \
  && ln -sf /usr/bin/chromium /usr/bin/google-chrome \
  && ln -sf /usr/bin/chromium /usr/bin/chromium-browser \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER rails:rails

FROM runtime-test AS runtime-dev

USER root

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    build-essential \
    less \
    libsqlite3-dev \
    libyaml-dev \
    pkg-config \
    vim-tiny \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER rails:rails

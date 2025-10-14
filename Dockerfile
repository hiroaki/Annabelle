# # For production environment
# $ docker build --build-arg RAILS_ENV=production -t annabelle-production:latest .
#
# # For staging environment
# $ docker build --build-arg RAILS_ENV=staging -t annabelle-staging:latest .
#
# # For development environment
# $ docker build --build-arg RAILS_ENV=development -t annabelle-development:latest .

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.4.4

ARG RAILS_ENV=production

FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim AS base

# Re-declare ARG before using it in ENV
ARG RAILS_ENV

# Rails app lives here
WORKDIR /rails

# Set environment with flexibility for staging/production
ENV BUNDLE_PATH="/usr/local/bundle" \
    RAILS_ENV=$RAILS_ENV

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems and run the application
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  build-essential \
  pkg-config \
  libyaml-dev \
  libsqlite3-dev \
  tzdata \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install application gems
COPY Gemfile Gemfile.lock ./
# NOTE:
# We use `bundle config set --local without 'development test'` and `bundle config set deployment true`
# instead of environment variables, because some tools (e.g. bootsnap precompile) require .bundle/config
# to correctly recognize excluded gem groups. Using only environment variables may cause build failures
# when gems in excluded groups are missing.
RUN if [ "$RAILS_ENV" = "development" ]; then \
      bundle config unset --local without; \
      bundle install; \
    else \
      bundle config set --local without 'development test'; \
      bundle config set deployment true; \
      bundle install; \
    fi && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile -j 0 --gemfile app/ lib/ config/

# Precompiling assets without requiring secret RAILS_MASTER_KEY
RUN if [ "$RAILS_ENV" != "development" ]; then \
      SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile; \
    else \
      echo "Skip assets:precompile in development"; \
    fi

# Final stage for app image
FROM base

# Install packages needed for deployment
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  curl \
  libsqlite3-0 \
  libvips \
  tzdata \
  ffmpeg \
  && if [ "$RAILS_ENV" = "development" ]; then \
    apt-get install --no-install-recommends -y \
      build-essential pkg-config libyaml-dev libsqlite3-dev vim-tiny less; \
  fi \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy built artifacts: application
COPY --from=build /rails /rails
COPY --from=build /usr/local/bundle /usr/local/bundle

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
    mkdir -p /rails/db /rails/log /rails/storage /rails/tmp /usr/local/bundle && \
    chown -R rails:rails /rails /usr/local/bundle

USER rails:rails

# Entrypoint prepares the database
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server with thruster for production/staging.
# Puma listening on port to THRUSTER_TARGET_PORT,
# kamal-proxy THRUSTER_HTTP_PORT for Thruster
ARG THRUSTER_HTTP_PORT=3001
ARG THRUSTER_TARGET_PORT=3000

ENV THRUSTER_HTTP_PORT=${THRUSTER_HTTP_PORT} \
    THRUSTER_TARGET_PORT=${THRUSTER_TARGET_PORT} \
    THRUSTER_DEBUG=1 \
    PORT=${THRUSTER_TARGET_PORT}
EXPOSE ${PORT}
CMD ["bundle", "exec", "thrust", "bin/rails", "server"]

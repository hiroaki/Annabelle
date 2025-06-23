#!/bin/bash
set -e

mkdir -p log tmp

if [ -z "$RAILS_ENV" ] || [ "$RAILS_ENV" = "development" ]; then
  bundle exec rails db:migrate
  bundle exec rails db:seed
  bundle exec rails tailwindcss:build
fi

exec "$@"

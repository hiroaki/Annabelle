#!/bin/bash
set -e

mkdir -p log tmp
bundle exec rails db:migrate
bundle exec rails db:seed
bundle exec rails tailwindcss:build
bundle exec rails assets:precompile

# This is in the development environment
bundle exec rails runner "User.admin_user.update!(password: 'password123')"

exec "$@"

web: bundle exec puma -C config/puma.rb
clock: bundle exec clockwork clock.rb
worker: bundle exec rake jobs:work
clockplusworker: bundle exec foreman start -f Procfile.clockplusworker

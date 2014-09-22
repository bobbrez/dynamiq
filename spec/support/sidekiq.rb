require 'sidekiq'
require 'sidekiq/testing'

Sidekiq.logger = nil
Sidekiq.redis = { namespace: 'dp_test' }

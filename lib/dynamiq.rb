require 'sidekiq'
require 'sidekiq/api'

require 'dynamiq/sidekiq/api'

require 'dynamiq/version'
require 'dynamiq/worker'
require 'dynamiq/client'
require 'dynamiq/job'
require 'dynamiq/fetcher'

module Dynamiq
  QUEUE_LIST = 'queues'
  DYNAMIC_QUEUE_LIST = 'dynamic_queues'
end

Sidekiq.options[:fetch] = Dynamiq::Fetcher

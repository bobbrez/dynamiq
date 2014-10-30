require 'sidekiq'

require 'dynamiq/version'
require 'dynamiq/worker'
require 'dynamiq/client'
require 'dynamiq/job'
require 'dynamiq/fetcher'
require 'dynamiq/queue'

module Dynamiq
  QUEUE_LIST = 'queues'
  DYNAMIC_QUEUE_LIST = 'dynamic_queues'
end

Sidekiq.options[:fetch] = Dynamiq::Fetcher

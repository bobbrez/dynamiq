require 'sidekiq'
require './lib/dynamiq'
require 'byebug'

class DefaultWorker
  include Sidekiq::Worker
  
  def perform(value)
    puts "DefaultWorker"
    sleep 20
    puts value
  end
end

class PrioritizedWorker
  include Dynamiq::Worker

  sidekiq_options queue: :dyqueue

  def perform(value)
    puts "PrioritizedWorker"
    sleep 20
    puts value
  end
end

class BrokenWorker
  include Sidekiq::Worker
  
  def perform(value)
    raise 'Some error'
  end
end

class BrokenPrioritizedWorker
  include Dynamiq::Worker

  sidekiq_options queue: :dyqueue

  def perform(value)
    raise 'Some error'
  end
end

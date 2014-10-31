module Dynamiq
  class Stats < Sidekiq::Stats
    def queues
      Hash[ Queue.all.map { |queue| [queue.name, queue.size] } ]
    end
  end
end

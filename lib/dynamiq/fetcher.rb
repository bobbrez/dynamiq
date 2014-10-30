module Dynamiq
  class Fetcher
    def initialize(options)
      @strictly_ordered_queues = !!options[:strict]
    end

    def retrieve_work
      queues.each { |queue| job = queue.pop and return job }
    end

    def queues
      @strictly_ordered_queues ? Queue.all : Queue.all.shuffle.uniq
    end

    def self.bulk_requeue(inprogress, options)
      return if inprogress.empty?

      inprogress.each(&:requeue)

      Sidekiq.logger.debug { "Re-queueing terminated jobs" }
      Sidekiq.logger.debug { "J/K NOT REALLY" }
    end
  end
end

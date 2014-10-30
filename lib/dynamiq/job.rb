module Dynamiq
  class Job
    attr_reader :queue, :message

    def initialize(queue, message)
      @queue = queue
      @message = message
    end
    
    def acknowledge
      # nothing to do
    end

    def queue_name
      queue.name
    end

    def requeue
      queue.requeue message
    end

    def delete
      deleted = Sidekiq.redis do |conn|
        rem_value = @value.dup
        rem_value.delete 'score'
        conn.zrem [:dynamic_queue, @queue].join(':'), rem_value.to_json
      end

      deleted ? 1 : 0
    end  
  end
end

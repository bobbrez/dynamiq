module Dynamiq
  class Job
    attr_reader :queue, :message, :item

    def initialize(queue, message = nil)
      @queue = queue
      @message = message
      @item = message.is_a?(Hash) ? message : Sidekiq.load_json(message)      
    end

    def klass
      @item['class']
    end

    def display_class
      # Unwrap known wrappers so they show up in a human-friendly manner in the Web UI
      @klass ||= case klass
                 when /\ASidekiq::Extensions::Delayed/
                   safe_load(args[0], klass) do |target, method, _|
                     "#{target}.#{method}"
                   end
                 when "ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper"
                   args[0]
                 else
                   klass
                 end
    end

    def display_args
      # Unwrap known wrappers so they show up in a human-friendly manner in the Web UI
      @args ||= case klass
                when /\ASidekiq::Extensions::Delayed/
                  safe_load(args[0], args) do |_, _, arg|
                    arg
                  end
                when "ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper"
                  args[1..-1]
                else
                  args
                end
    end

    def args
      @item['args']
    end

    def jid
      @item['jid']
    end

    def score
      @item['score']
    end

    def enqueued_at
      Time.at(@item['enqueued_at'] || 0).utc
    end

    def latency
      Time.now.to_f - @item['enqueued_at']
    end

    def acknowledge
      # nothing to do
    end

    def [](name)
      @item.__send__(:[], name)
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

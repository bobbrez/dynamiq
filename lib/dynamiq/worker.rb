module Dynamiq
  module Worker
    def self.included(base)
      base.class.include Sidekiq::Worker
      base.extend Sidekiq::Worker::ClassMethods
      base.extend ClassMethods
    end

    module ClassMethods
      def perform_async(score, *args)
        client_push score: score, class: self, args: args
      end

      def perform_in(interval, score, *args)
        int = interval.to_f
        now = Time.now.to_f
        ts = (int < 1_000_000_000 ? now + int : int)

        item = { score: score, class: self, args: args, at: ts }

        # Optimization to enqueue something now that is scheduled to go out now or in the past
        item.delete 'at' if ts <= now

        client_push item
      end
      alias_method :perform_at, :perform_in

      def client_push(item) # :nodoc:
        pool = Thread.current[:sidekiq_via_pool] || get_sidekiq_options['pool'] || Sidekiq.redis_pool
        Dynamiq::Client.new(pool).push(item.stringify_keys)
      end 
    end
  end
end

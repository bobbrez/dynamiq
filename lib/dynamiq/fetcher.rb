module Dynamiq
  class Fetcher
    UnitOfWork = Struct.new(:queue, :message, :priority) do
      def acknowledge
        # nothing to do
      end

      def queue_name
        queue.gsub(/.*queue:/, '')
      end

      def requeue
        Sidekiq.redis do |conn|
          conn.rpush("queue:#{queue_name}", message)
        end
      end
    end

    class Queue
      attr_reader :name

      REDIS_RPOPZADD = "local value = redis.call('zrange', KEYS[1], -1, -1)[1]
        local score = redis.call('zscore', KEYS[1], value)
        redis.call('zremrangebyrank', KEYS[1], -1, -1)
        return { value, score }"


      def initialize(name)
        @name = name
      end

      def dynamic?
        @dynamic ||= Sidekiq.redis { |redis| redis.sismember Dynamiq::DYNAMIC_QUEUE_LIST, name }
      end

      def eql?(obj)
        return false unless obj.respond_to? :name

        name.eql? obj.name
      end

      def hash
        name.hash
      end

      def rname
        @rname ||= begin
          rname = [ dynamic? ? Dynamiq::DYNAMIC_QUEUE_LIST : Dynamiq::QUEUE_LIST ]
          rname << name
          rname.join ':'
        end
      end

      def fetch_next
        if dynamic?
          byebug
          Sidekiq.redis { |redis| redis.eval REDIS_RPOPZADD, [rname] }
        else
          Sidekiq.redis { |redis| redis.brpop rname, 1 }
        end
      end
    end

    def initialize(options)
      @strictly_ordered_queues = !!options[:strict]
      @queues = options[:queues].map { |q| Queue.new q }
      @unique_queues = @queues.uniq
    end

    def retrieve_work
      job = nil
      queue = queues_cmd.each do |queue|
        job = queue.fetch_next
        break if job
      end

      UnitOfWork.new [queue, job].flatten if job
    end

    def queues_cmd
      @strictly_ordered_queues ? @unique_queues.dup : @queues.shuffle.uniq
    end
  end
end

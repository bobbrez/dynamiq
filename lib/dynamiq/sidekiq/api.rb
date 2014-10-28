module Sidekiq
  class Queue
    attr_reader :name

    def initialize(name = 'default')
      @name = name
      @rname = [ Dynamiq::DYNAMIC_QUEUE_LIST, name ].join(':')
    end

    def dynamic? 
      @dynamic ||= Sidekiq.redis { |redis| redis.sismember Dynamiq::DYNAMIC_QUEUE_LIST, @name }
    end

    def size
      return super unless dynamic?

      Sidekiq.redis { |redis| redis.zcount @rname, '-inf', '+inf' }
    end

    def each(&block)
      return super unless dynamic?

      initial_size = size
      deleted_size = 0
      page = 0
      page_size = 50

      loop do
        start = page * page_size - deleted_size
        
        entries = Sidekiq.redis do |redis|
          limit = [start, page_size]
          redis.zrangebyscore @rname, '-inf', '+inf', limit: limit, with_scores: true
        end

        break if entries.empty?

        page += 1
        entries.each do |entry|
          block.call Dynamiq::Job.new(*entry, @name)
        end

        deleted_size = initial_size - size
      end
    end

    def ==(object)
      object.respond_to?(:name) and @name == object.name
    end

    def clear
      return super unless dynamic?

      Sidekiq.redis do |redis|
        redis.multi do
          redis.del @rname
          redis.srem Dynamiq::DYNAMIC_QUEUE_LIST, name
        end
      end
    end
    alias_method :💣, :clear

    def self.all_dynamic
      Sidekiq.redis { |redis| redis.smembers Dynamiq::DYNAMIC_QUEUE_LIST }
        .sort
        .map { |q| Queue.new q }
    end 
  end
end

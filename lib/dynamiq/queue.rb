module Dynamiq
  class Queue
    include Enumerable

    attr_reader :name, :path

    REDIS_RPOPZADD = "local value = redis.call('zrange', KEYS[1], -1, -1)[1]
      local score = redis.call('zscore', KEYS[1], value)
      redis.call('zremrangebyrank', KEYS[1], -1, -1)
      return { value, score }"

    def initialize(name = 'default')
      @name = name
      @path = [ (dynamic? ? :dynamic_queue : :queue), name].join(':')
    end

    def dynamic?
      @dynamic ||= Sidekiq.redis { |redis| redis.sismember :dynamic_queues, name }
    end

    def paused?
      false
    end

    def requeue(message)
      if dynamic?
        Dynamiq::Client.new.push_message message
      else
        Sidekiq.redis { |redis| redis.rpush path, message }
      end
    end

    def pop
      job = pop_job and Job.new self, job
    end

    def each(&block)
      initial_size = size
      deleted_size = 0
      page = 0
      page_size = 50

      loop do
        start = page * page_size - deleted_size
        entries = fetch_jobs start, page_size

        break if entries.empty?

        page += 1
        entries.each do |entry|
          block.call Job.new(*entry, @name)
        end

        deleted_size = initial_size - size
      end
    end

    def latency
      method = dynamic? ? :zrange : :lrange
      entry = Sidekiq.redis { |redis| redis.send(method, path, -1, -1) }.first
      return 0 unless entry
      Time.now.to_f - Sidekiq.load_json(entry)['enqueued_at']
    end
    
    def clear
      index_list = dynamic? ? :dynamic_queues : :queues

      Sidekiq.redis do |redis|
        redis.multi do
          redis.del path
          redis.srem index_list, name
        end
      end
    end
    alias_method :💣, :clear

    def size
      if dynamic?
        Sidekiq.redis { |redis| redis.zcount path, '-inf', '+inf' }
      else
        Sidekiq.redis { |redis| redis.llen path }
      end
    end

    def eql?(obj)
      return false unless obj.respond_to? :name

      name.eql? obj.name
    end

    def hash
      name.hash
    end

    def ==(object)
      object.respond_to?(:name) and @name == object.name
    end

    def self.dynamic
      Sidekiq.redis { |redis| redis.smembers :dynamic_queues }
        .sort
        .map { |queue| Queue.new queue }
    end

    def self.fifo
      queues = Sidekiq.redis { |redis| redis.smembers :queues }
      dynamic = Sidekiq.redis { |redis| redis.smembers :dynamic_queues }
      (queues - dynamic).sort.map { |queue| Queue.new queue }
    end


    def self.all
      Sidekiq.redis { |redis| redis.smembers 'queues' }
        .sort
        .map { |queue| Queue.new queue }
    end

  private

    def fetch_jobs(start, page_size)
      Sidekiq.redis do |redis|
        if dynamic?
          limit = [start, page_size]
          redis.zrangebyscore @rname, '-inf', '+inf', limit: limit, with_scores: true
        else
          redis.lrange @rname, start, (start + page_size - 1)
        end
      end
    end

    def pop_job
      if dynamic?
        job = Sidekiq.redis { |redis| redis.eval REDIS_RPOPZADD, [ path ] }
        return nil if job.empty?
        JSON.parse(job.first).merge(score: job.last.to_f).to_json
      else
        Sidekiq.redis { |redis| redis.rpop path }
      end
    end
  end
end

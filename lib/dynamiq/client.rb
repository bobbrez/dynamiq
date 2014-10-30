module Dynamiq
  class Client < Sidekiq::Client
    def push_message(message)
      redis_pool.with do |conn|
        atomic_push conn, [ JSON.parse(message) ]
      end
    end

  private

    def atomic_push(conn, payloads)
      if payloads.first['at']
        payload = payloads.map do |hash|
          [ hash.delete('at').to_s, Sidekiq.dump_json(hash) ]
        end
        
        conn.zadd 'schedule', payload
      else
        q = payloads.first['queue']
        to_push = payloads.map do |entry| 
          [ entry.delete('score').to_i, Sidekiq.dump_json(entry) ]
        end

        conn.sadd :queues, q
        conn.sadd :dynamic_queues, q
        conn.zadd [:dynamic_queue, q].join(':'), to_push
      end
    end
  end
end

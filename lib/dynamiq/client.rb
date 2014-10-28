module Dynamiq
  class Client < Sidekiq::Client
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

        conn.sadd Dynamiq::DYNAMIC_QUEUE_LIST, q
        conn.sadd Dynamiq::QUEUE_LIST, q
        conn.zadd [Dynamiq::DYNAMIC_QUEUE_LIST, q].join(':'), to_push
      end
    end
  end
end

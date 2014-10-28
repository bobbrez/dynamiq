module Dynamiq
  class Job < Sidekiq::Job
    attr_reader :score

    def initialize(item, score, queue_name = nil)
      @value = item
      @score = score
      @item = item.is_a?(Hash) ? item : Sidekiq.load_json(item)
      @item.merge! 'score' => score
      @queue = queue_name || @item['queue']
    end

    def delete
      deleted = Sidekiq.redis do |conn|
        rem_value = @value.dup
        rem_value.delete 'score'
        conn.zrem [Dynamiq::DYNAMIC_QUEUE_LIST, @queue].join(':'), rem_value.to_json
      end

      deleted ? 1 : 0
    end    
  end
end

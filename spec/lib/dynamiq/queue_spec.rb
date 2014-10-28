require 'spec_helper'

describe Dynamiq::Queue do
  before(:each) { Sidekiq.redis { |redis| redis.flushall } }

  context '#size' do
    it "returns 0 if the queue doesn't exist" do
      expect(Dynamiq::Queue.new.size).to eq 0
    end

    it 'returns the number of items in the queue' do
      count = Random.rand 50
      count.times { redis_queue_job 'foo', 0 }
      expect(Dynamiq::Queue.new('foo').size).to eq count
    end
  end

  context '#each' do
    it 'loops through each queued job' do
      200.times { |i| redis_queue_job 'foo', i, index: i }

      queue = Dynamiq::Queue.new 'foo'

      current_score = 0
      queue.each do |job|
        expect(job.score).to eq current_score
        current_score += 1
      end
    end
  end

  context '#clear' do
    it 'clears the items in the queue and removes it from the list of queues' do
      200.times { |i| redis_queue_job 'foo', i, index: i }

      queue = Dynamiq::Queue.new 'foo'
      expect(queue.size).to eq 200

      queue.clear

      expect(queue.size).to eq 0
      expect(Dynamiq::Queue.all).not_to include(Dynamiq::Queue.new('foo'))
    end
  end

  context '#==' do
    it 'is true when the queus have the same name' do
      q1, q2 = Dynamiq::Queue.new('foo'), Dynamiq::Queue.new('foo')
      expect(q1 == q2).to be true
    end

    it 'is false when the queues have different names' do
      q1, q2 = Dynamiq::Queue.new('foo'), Dynamiq::Queue.new('bar')
      expect(q1 == q2).to be false
    end
  end

  context '.all' do
    it 'returns all dynamic queues' do
      queues = %w(foo bar biz)

      redis_add_queues queues

      expect(Dynamiq::Queue.all).to eq(queues.sort.map { |q| Dynamiq::Queue.new q })
    end
  end
end

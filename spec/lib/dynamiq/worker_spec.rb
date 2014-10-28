require 'spec_helper'

describe Dynamiq::Worker do
  before(:each) { Sidekiq.redis { |redis| redis.flushall }}

  class SimpleWorker
    include Dynamiq::Worker
  end

  subject { SimpleWorker }

  context '#perform_async' do
    it 'queues the job with a numeric priority' do
      queue = Dynamiq::Queue.new

      expect(queue.size).to eq 0

      subject.perform_async 10, arg1: 'arg1'

      expect(queue.size).to eq 1

      job = queue.first.item.slice('queue', 'score', 'args')
      expect(job).to eq({ 'queue' => 'default',
                          'score' => 10,
                          'args' => [{ 'arg1' => 'arg1' }]})
    end
  end

  context '#perform_in' do
    it 'queues the job for a later time' do
      Timecop.freeze do
        perform_at = 86_400
        subject.perform_in perform_at, 10, arg1: 'arg1'
      
        scheduled = Sidekiq::ScheduledSet.new
        expect(scheduled.size).to eq 1

        exec_at = scheduled.first.score
        expect(exec_at).to eq (Time.now + perform_at).to_f

        job = scheduled.first.item.slice('queue', 'score', 'args')
        expect(job).to eq({ 'queue' => 'default',
                            'score' => 10,
                            'args' => [{ 'arg1' => 'arg1' }]})
      end
    end
  end
end

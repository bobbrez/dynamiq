require 'sidekiq/web'

require 'dynamiq/web_helpers'
require 'dynamiq/stats'

module Dynamiq
  class Web < Sidekiq::Web
    helpers WebHelpers

    get "/queues" do
      @queues = Dynamiq::Queue.all
      erb :queues
    end

    get "/queues/:name" do
      halt 404 unless params[:name]
      @count = (params[:count] || 25).to_i
      @name = params[:name]
      @queue = Dynamiq::Queue.new @name
      (@current_page, @total_size, @messages) = page(@queue.path, params[:page], @count)
      @messages = @messages.map { |msg| 
        Dynamiq::Job.new @queue, (msg.respond_to?(:first) ? msg.first : msg)
      }
      @queue.size
      erb :queue
    end

    post "/queues/:name" do
      Dynamiq::Queue.new(params[:name]).clear
      redirect "#{root_path}queues"
    end

    post "/queues/:name/delete" do
      byebug
      Dynamiq::Job.new(params[:key_val], params[:name]).delete
      redirect_with_query("#{root_path}queues/#{params[:name]}")
    end

    get '/dashboard/stats' do
      sidekiq_stats = Dynamiq::Stats.new
      queue         = Dynamiq::Queue.new
      redis_stats   = redis_info.select{ |k, v| REDIS_KEYS.include? k }

      content_type :json
      Sidekiq.dump_json({
        sidekiq: {
          processed:  sidekiq_stats.processed,
          failed:     sidekiq_stats.failed,
          busy:       workers_size,
          enqueued:   sidekiq_stats.enqueued,
          scheduled:  sidekiq_stats.scheduled_size,
          retries:    sidekiq_stats.retry_size,
          dead:       sidekiq_stats.dead_size,
          default_latency: queue.latency,
        },
        redis: redis_stats
      })
    end    
  end
end


require 'sidekiq'
require './lib/dynamiq'
require 'byebug'

byebug

class PrioritizedWorker
  include Dynamiq::Worker

  sidekiq_options queue: :dyqueue

  def perform(value)
    puts value
  end
end

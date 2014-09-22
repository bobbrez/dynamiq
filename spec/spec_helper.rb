$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'pry'
require 'pry-byebug'

Dir[File.join './spec/support/**/*.rb'].each { |f| require f }

require File.expand_path('../../lib/dynamiq', __FILE__)

RSpec.configure do |config|
  config.profile_examples = 10

  Kernel.srand config.seed
  config.order = :random
end

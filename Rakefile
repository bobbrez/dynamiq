require 'bundler/gem_tasks'

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new :spec

task default: :spec

require 'byebug'

task :monitor do
  require './lib/dynamiq'
  require 'sinatra'
  require './lib/dynamiq/web'
  app = Dynamiq::Web
  app.set :environment, :production
  app.set :bind, '0.0.0.0'
  app.set :port, 9494
  app.run!
end

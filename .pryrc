require 'awesome_print'

Pry.config.hooks.add_hook :before_session, :load_project_lib do
  dir = `pwd`.chomp
  %w(lib spec test).map { |d| "#{dir}/#{d}" }.each { |p|  $: << p unless !File.exist?(p) || $:.include?(p) }
  require 'dynamiq'
end


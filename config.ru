require 'sidekiq'
require 'sidekiq/web'
require './lib/apps/ampify'
run Sinatra::Application
map '/sidekiq' do
  run Sidekiq::Web
end


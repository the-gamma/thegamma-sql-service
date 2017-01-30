require 'rack/cors'
require './lib/service.rb'

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: :get
  end
end

run Cuba

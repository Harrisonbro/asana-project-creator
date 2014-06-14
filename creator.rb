require 'json'
require 'Asana'

config = JSON.parse(File.read('config.json'))

Asana.configure do |client|
  client.api_key = config['api_key']
end

puts Asana::User.me
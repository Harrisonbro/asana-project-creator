# Dependencies
require 'json'
require 'Asana'

# Configuration
config = JSON.parse(File.read('config.json'))

Asana.configure do |client|
  client.api_key = config['api_key']
end

# Ask user to choose a workspace
workspaces = Asana::Workspace.all
workspaces.each { |workspace|
    p workspace.name
}
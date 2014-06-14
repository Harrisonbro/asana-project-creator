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
puts "Which workspace should this project be created in?"
puts "  (type your chosen number, then press enter)"
workspaces.each_with_index { |workspace, index|
    puts "  [#{index}] #{workspace.name}"
}
workspace_index = gets
workspace = workspaces[workspace_index.to_i]
puts "OK, creating project in the #{workspace.name} workspace"
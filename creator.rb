#
# Dependencies
#
require 'json'
require 'Asana'

#
# Configuration
#
config = JSON.parse(File.read('config.json'))

Asana.configure do |client|
  client.api_key = config['api_key']
end

puts "Talking to Asana..."

#
# Ask user to choose a workspace
#
workspaces = Asana::Workspace.all

puts "Which workspace should this project be created in?\n\n"

def ask_for_workspace(workspaces)
    workspaces.each_with_index { |workspace, index|
        puts "  [#{index}] #{workspace.name} (id: #{workspace.id})"
    }

    puts "\n→ Type your choice and press enter..."

    workspace_index = Integer(gets) rescue -1

    if workspaces[workspace_index].nil?
        puts "Your answer wasn't valid. Please choose from the following options:\n\n"
        ask_for_workspace(workspaces)
    else
        workspace = workspaces[workspace_index]
        return workspace
    end
end

workspace = ask_for_workspace(workspaces)

puts workspace.id

puts "\nOK, creating project in the #{workspace.name} workspace"
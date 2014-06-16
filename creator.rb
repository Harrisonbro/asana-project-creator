#
# Dependencies
#
require 'yaml'
require 'Asana'

#
# Configuration
#
config = YAML.load_file('config.yaml')

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

    if workspace_index < 0 || workspaces[workspace_index].nil?
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

#
# Ask user to choose template
#

templates = []
Dir.glob("templates/**.yaml") { |entry|
    template = YAML.load_file(entry)
    templates << template
}

puts "Which project template do you want to use?\n\n"

def ask_for_template(templates)
    templates.each_with_index { |template, index|
        puts "  [#{index}] #{template['template_name']}"
    }

    puts "\n→ Type your choice and press enter..."

    template_index = Integer(gets) rescue -1

    if template_index < 0 || templates[template_index].nil?
        puts "Your answer wasn't valid. Please choose from the following options:\n\n"
        ask_for_template(templates)
    else
        template = templates[template_index]
        return template
    end
end

template = ask_for_template(templates)

puts "\nOK, creating a new project from the #{template['template_name']} template"
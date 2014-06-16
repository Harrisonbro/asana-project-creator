#
# Dependencies
#
require 'pp'
require 'yaml'
require 'Asana'

#
# Kickoff
#

puts "Starting Asana Project Creator."
puts "Press Ctrl+Z at any time to force-quit the script."

#
# Configuration
#
config = YAML.load_file('config.yaml')

Asana.configure do |client|
  client.api_key = config['api_key']
end

puts "Talking to Asana....."

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

#
# Ask for date
#
puts "\nWhat date should the template's tasks be created relative to?\n\n"

def ask_for_year()
    puts "→ Year: (eg. #{Time.now.year})"

    year = String(gets.gsub("\n",'')) rescue -1
    year_int = Integer(year) rescue -1

    if year == -1 || year.size != 4 || year_int < 0
        puts "\nPlease type the year as a 4-digit number (eg. #{Time.now.year})"
        ask_for_year()
    else
        return year.to_i
    end
end

def ask_for_month()
    puts "→ Month: (eg. #{Time.now.strftime '%m'})"

    month = String(gets.gsub("\n",'')) rescue -1
    month_int = Integer(month) rescue -1

    if month == -1 || month.size != 2 || month_int < 0
        puts "\nPlease type the month as a 2-digit number (eg. #{Time.now.strftime '%m'})"
        ask_for_month()
    else
        return month.to_i
    end
end

def ask_for_day()
    puts "→ Day: (eg. #{Time.now.strftime '%d'})"

    day = String(gets.gsub("\n",'')) rescue -1
    day_int = Integer(day) rescue -1

    if day == -1 || day.size != 2 || day_int < 0
        puts "\nPlease type the day as a 2-digit number (eg. #{Time.now.strftime '%d'})"
        ask_for_day()
    else
        return day.to_i
    end
end

year = ask_for_year()
month = ask_for_month()
day = ask_for_day()

relative_date = Date.new(year, month, day)
puts "\nOK, creating tasks relative to #{relative_date.strftime('%A %-d %b %Y')}"

#
# Build up dates on tasks to be created
#
template['tasks'].each { |task|
    task['date'] = relative_date + task['days'].to_i
}

puts "\nRight, we'll create a project called '#{template['template_name']}'"
puts "in the #{workspace.name} workspace with the following tasks:"
puts "-----------------------------------------------------------------------"

template['tasks'].each { |task|
    puts "- #{task['title']}"
    puts "  Due on: #{task['date'].strftime('%A %-d %b %Y')}"
}

puts "-----------------------------------------------------------------------"

#
# Create the tasks
#
puts "\nTelling Asana to create the tasks (this may take a minute or two).....\n\n"

# workspace.create_project(:name => "test project name", :workspace => workspace.id)
# workspace.create_task(:name => "test task name")
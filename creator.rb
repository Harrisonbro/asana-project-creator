#
# Dependencies
#
require 'date'
require 'pp'
require 'yaml'
require 'Asana'
require 'typhoeus'

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
workspaces = Asana::Workspace.find(:all, :params => { :opt_fields => "name, is_organization" })
workspaces = workspaces.elements

# Remove "Personal Projects" workspace from options
workspaces.each_with_index { |workspace, index|
    if workspace.name == "Personal Projects"
        workspaces.delete_at(index)
    end
}

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

puts "\nOK, we'll create this project in the #{workspace.name} workspace"

#
# Show users in workspace
#

puts "Asking Asana about your workspace's users...."
users = workspace.users

puts "\nThe users in this workspace are:"

users.each { |user|
    puts "- #{user.name} (id: #{user.id})"
}

puts "\nYou can use these user IDs in the project templates to assign tasks to users. Make sure you always create a template in the right workspace/team (or invite these users into your workspaces/teams) so the user(s) are available to have tasks assigned to them. To leave a task unassigned just leave the task's assignee field in the template blank."

#
# Ask user to choose team to create in
#

if workspace.is_organization
    puts "\nAsking Asana about this workspace's teams....."

    request = Typhoeus::Request.new(
        "https://app.asana.com/api/1.0/organizations/#{workspace.id}/teams",
        method: :get,
        userpwd: "#{config['api_key']}:"
    )

    request.on_complete do |response|
        if response.success?
            # hell yeah
        elsif response.timed_out?
            # aw hell no
            log("got a time out")
        elsif response.code == 0
            # Could not get an http response, something's wrong.
            log(response.return_message)
        else
            # Received a non-successful http response.
            puts "Sorry, something went wrong with the API request (returned response code #{response.code.to_s})"
            exit
        end
    end

    request.run
    response = request.response

    response = JSON.parse(response.body)
    teams = response['data']

    if teams.size == 0
        puts "\nHmm, looks like you don't have any teams in the #{workspace.name} workspace, but that workspace is an Asana 'organization' so you need to first create a team within it before we can carry on. Do that and then come back!"
        exit
    else
        puts "\nWhich team within #{workspace.name} should we create the project in?\n\n"

        def ask_for_team(teams)
            teams.each_with_index { |team, index|
                puts "  [#{index}] #{team['name']} (id: #{team['id']})"
            }

            puts "\n→ Type your choice and press enter..."

            team_index = Integer(gets) rescue -1

            if team_index < 0 || teams[team_index].nil?
                puts "Your answer wasn't valid. Please choose from the following options:\n\n"
                ask_for_team(teams)
            else
                team = teams[team_index]
                return team
            end
        end

        team = ask_for_team(teams)

        puts "\nOK, creating within the '#{team['name']}' team"
    end
end

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

def create_date_field(task, relative_date)
    if task.has_key?('days')
        task['date'] = relative_date + task['days'].to_i
    end

    if task.has_key?('subtasks') && task['subtasks'].any?
        task['subtasks'].each { |subtask|
            create_date_field(subtask, relative_date)
        }
    end
end

template['tasks'].each { |task|
    create_date_field(task, relative_date)
}

puts "\n→ What should this project be called?"

project_name = gets.gsub("\n",'')

puts "\nRight, we'll create a project called '#{project_name}' in the #{workspace.name} workspace with the following tasks:"
puts "-----------------------------------------------------------------------"

def put_task_to_console(task, indent=0)
    indentation = "  "
    task_name = "- #{task['title']}"
    indent.times {
        task_name = indentation + task_name
    }
    puts task_name

    if task.has_key?('date')
        task_date = "  (due on: #{task['date'].strftime('%A %-d %b %Y')})"
        indent.times {
            task_date = indentation + task_date
        }
        puts task_date
    end

    if task.has_key?('subtasks') && task['subtasks'].any?
        task['subtasks'].each { |subtask|
            put_task_to_console(subtask, indent.next)
        }
    end
end

template['tasks'].each { |task|
    put_task_to_console(task)
}

puts "-----------------------------------------------------------------------"

#
# Create the tasks
#

puts "\nTelling Asana to create the tasks (this may take a minute or two).....\n\n"

if workspace.is_organization
    project = workspace.create_project(:name => project_name, :team => team['id'])
else
    project = workspace.create_project(:name => project_name)
end
puts "Created #{project.name}..."

def create_new_task(task, workspace, project, parent_id=nil)
    task_data = {}

    if task.has_key?('title') && task['title'].is_a?(String)
        if task['title'].strip.empty?
            puts "One of your tasks didn't have a name so couldn't be created"
        else
            task_data[:name] = task['title']
        end
    else
        puts "One of your tasks didn't have a name so couldn't be created"
        return
    end

    if task.has_key?('assignee')
        task_data[:assignee] = task['assignee'] rescue ""
    end

    if task.has_key?('notes')
        task_data[:notes] = task['notes']
    end

    if task.has_key?('date') && task['date'].is_a?(Date)
        task_data[:due_on] = task['date'].strftime('%Y-%m-%d')
    end

    unless parent_id.nil?
        task_data[:parent] = parent_id
    end

    newtask = workspace.create_task(task_data)
    newtask.add_project(project.id)

    puts "Created #{task['title']}..."

    if task.has_key?('subtasks') && task['subtasks'].any?
        task['subtasks'].each { |subtask|
            create_new_task(subtask, workspace, project, newtask.id)
        }
    end
end

template['tasks'].each_with_index { |task, index|
    create_new_task(task, workspace, project)
}

puts "\nAll done!!"

exit

project_url = "https://app.asana.com/0/#{project.id}/#{project.id}"
puts "The project's URL should be #{project_url}"
system("open #{project_url}")
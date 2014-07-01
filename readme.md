# Asana Project Creator

A simple command-line tool to create Asana projects from a template.

### Installation
Asana Project Creator requires [`asana`](https://rubygems.org/gems/asana) and [`typhoeus`](https://github.com/typhoeus/typhoeus). To install, run `sudo gem install asana typhoeus`.

You'll also need to create a config file. Copy `config.sample.yaml` to `config.yaml` and add your [API key](http://app.asana.com/-/account_api) and other details.

### Usage
First create your template(s) within the `templates` director. Use `templates/example.rb` as a starting point.

Once you've created your templates simply run `ruby creator.rb` from the project root folder and follow the on-screen instructions.
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'rake/dsl_definition'
require 'backburner/tasks'

include Rake::DSL
Primero::Application.load_tasks

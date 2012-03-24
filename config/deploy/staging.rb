# Add RVM's lib directory to the load path.
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))

# Load RVM's capistrano plugin.
require "rvm/capistrano"

set :rvm_ruby_string, 'ruby-1.9.2-p318'
set :rvm_type, :user

set :rails_env, 'staging'
set :deploy_to, "/home/#{user}/apps/#{application}/staging"

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} unicorn server"
    task command, roles: :app, except: {no_release: true} do
      run "/etc/init.d/unicorn_#{application}_staging #{command}"
    end
  end
end

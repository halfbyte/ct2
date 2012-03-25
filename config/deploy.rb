require 'capistrano/ext/multistage'
require "bundler/capistrano"

# Add RVM's lib directory to the load path.
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))

# Load RVM's capistrano plugin.
require "rvm/capistrano"

set :rvm_ruby_string, 'ruby-1.9.2-p318'
set :rvm_type, :user

server "46.163.76.165", :web, :app, :db, primary: true

set :application, "cloudtracker"
set :user, "cloudtracker"

set :stages, %w(staging production)
set :default_stage, 'staging'

set :deploy_via, :rsync_with_remote_cache
set :use_sudo, false

set :scm, "git"
set :repository, "git@github.com:halfbyte/ct2.git"
set :branch, "master"

set :port, 54321

default_run_options[:pty] = true
ssh_options[:forward_agent] = true
ssh_options[:port] = 54321

after "deploy", "deploy:cleanup" # keep only the last 5 releases

namespace :deploy do
  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/uploads #{release_path}/public/uploads"
  end
  after "deploy:finalize_update", "deploy:symlink_config"

  desc "Make sure local git is in sync with remote."
  task :check_revision, roles: :web do
    unless `git rev-parse HEAD` == `git rev-parse origin/master`
      puts "WARNING: HEAD is not the same as origin/master"
      puts "Run `git push` to sync changes."
      exit
    end
  end
  before "deploy", "deploy:check_revision"
end
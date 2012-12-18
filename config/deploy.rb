set :application, "ct2"
set :repository,  "git@github.com:halfbyte/ct2.git"

set :scm, :git # You can set :scm explicitly or Capistrano will make an intelligent guess based on known version control directory names
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

set :rvm_ruby_string, '1.9.3@ct2'

set :deploy_to, '/srv/ct2'
set :user, 'ct2'

set :use_sudo, false

role :web, "vetinari.krutisch.de"                          # Your HTTP server, Apache/etc
role :app, "vetinari.krutisch.de"                          # This may be the same as your `Web` server
role :db,  "vetinari.krutisch.de", :primary => true # This is where Rails migrations will run

require "rvm/capistrano"
require 'capistrano-unicorn'
require "bundler/capistrano"


task :set_symlinks do
  run "rm #{release_path}/config/database.yml"
  run "ln -s #{shared_path}/config/database.yml #{release_path}/config/database.yml"
end

after 'deploy:update_code', :set_symlinks

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

after 'deploy:restart', 'unicorn:restart'
after 'deploy:start', 'unicorn:start'
after 'deploy:stop', 'unicorn:stop'

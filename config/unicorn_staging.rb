current_path = "/home/cloudtracker/apps/cloudtracker/staging/current"
shared_path = "/home/cloudtracker/apps/cloudtracker/staging/shared"

working_directory current_path

pid "#{current_path}/tmp/pids/unicorn.pid"
stderr_path "#{current_path}/log/unicorn.log"
stdout_path "#{current_path}/log/unicorn.log"

listen "/tmp/unicorn.cloudtracker-staging.sock"
worker_processes 2
timeout 30

before_exec do |server|
  ENV['GEM_HOME'] = ENV['GEM_PATH'] = "#{shared_path}/bundle"
  ENV['BUNDLE_GEMFILE'] = "#{current_path}/Gemfile"
end
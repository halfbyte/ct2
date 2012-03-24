set :rails_env, 'production'
set :deploy_to, "/home/#{user}/apps/#{application}/production"

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} unicorn server"
    task command, roles: :app, except: {no_release: true} do
      run "/etc/init.d/unicorn_#{application}_production #{command}"
    end
  end
end

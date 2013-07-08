require "dotenv"
require "bundler/capistrano"
default_run_options[:shell] = '/bin/bash --login' 
Dotenv.load

# deploy command: cap -S branch="<branchname>" deploy
set :user, "deploy"
set :password, ENV["DEPLOY_PASSWORD"] # The deploy user's password
set :application, "helios-test"

set :repository, "git@github.com:tehviking/helios-test.git" # Your clone URL
set :scm, "git"
set :branch, fetch(:branch, "master")
set :scm_verbose, true
set :deploy_via, :remote_cache
set :deploy_to, "/home/#{user}/#{application}"
set :use_sudo, false

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

role :web, "198.61.231.71" # Your HTTP server, Apache/etc
role :app, "198.61.231.71" # This may be the same as your `Web` server
role :db, "198.61.231.71" , :primary => true # This is where Rails migrations will run

namespace :deploy do
  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/.env #{release_path}/.env"
  end
end


namespace :foreman do
  desc "Export the Procfile to Ubuntu's upstart scripts"
  task :export, :roles => :app do
    run "cd /home/#{user}/#{application} && sudo bundle exec foreman export upstart /etc/init -a #{application} -u deploy -l /var/#{application}/log"
  end
  
  desc "Start the application services"
  task :start, :roles => :app do
    sudo "start #{application}"
  end

  desc "Stop the application services"
  task :stop, :roles => :app do
    sudo "stop #{application}"
  end

  desc "Restart the application services"
  task :restart, :roles => :app do
    run "sudo start #{application} || sudo restart #{application}"
  end
end

after "deploy:update", "foreman:export"
after "deploy:update", "foreman:restart"

after 'deploy:update_code', 'deploy:symlink_shared'
after "foreman:restart", "deploy:cleanup"

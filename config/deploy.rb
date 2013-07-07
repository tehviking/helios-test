require "bundler/capistrano"

# deploy command: cap -S branch="<branchname>" deploy
set :user, "deploy"
set :application, "wade-app"

set :repository, "git@github.com:tehviking/friendfocus.git" # Your clone URL
set :scm, "git"
set :branch, fetch(:branch, "master")
set :scm_verbose, true
set :deploy_via, :remote_cache
set :scm_passphrase, ENV["DEPLOY_PASSWORD"] # The deploy user's password
set :deploy_to, "/home/#{user}/#{application}"
set :use_sudo, false

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

role :web, "198.61.231.71" # Your HTTP server, Apache/etc
role :app, "198.61.231.71" # This may be the same as your `Web` server
role :db, "198.61.231.71" , :primary => true # This is where Rails migrations will run

namespace :deploy do
  # task :restart_passenger do
  #   run "touch #{current_path}/tmp/restart.txt"
  # end

  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/.env #{release_path}/.env"
  end

end

after 'deploy:update_code', 'deploy:symlink_shared'
after "deploy:restart", "deploy:cleanup"

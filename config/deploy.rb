require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'
require 'mina/puma'
require 'mina_sidekiq/tasks'

set :application_name, 'ihzau'
set :domain, 'ihzau.org'
set :user, 'deploy'
set :deploy_to, "/home/#{fetch(:user)}/ihzau"
set :app_path, -> { "#{fetch(:deploy)}/#{fetch(:current_path)}" }
set :repository, 'git@github.com:ihzau/homeland.git'
set :branch, 'feature/mina'
set :term_mode, nil
set :shared_paths, ['log', 'tmp']

set :shared_dirs, fetch(:shared_dirs, []).push('log', 'tmp/pids', 'tmp/sockets', 'public/uploads')
set :shared_files, fetch(:shared_files, []).push('config/puma.rb', 'config/database.yml', 'config/config.yml', 'config/elasticsearch.yml', 'config/redis.yml', 'config/secrets.yml', 'config/memcached.yml', 'config/cable.yml')

set :sidekiq_pid, -> { "#{fetch(:shared_path)}/tmp/pids/sidekiq.pid" }

set :puma_config,    -> { "#{fetch(:shared_path)}/config/puma.rb" }
set :puma_pid, -> { "#{fetch(:shared_path)}/tmp/pids/puma.pid" }
set :puma_state, -> { "#{fetch(:shared_path)}/tmp/pids/puma.state" }
set :pumactl_socket, -> { "#{fetch(:shared_path)}/tmp/sockets/pumactl.sock" }

task :remote_environment do
  invoke :'rbenv:load'
end

task :setup do
  command %{ export PATH="$HOME/.rbenv/bin:$PATH" }

  command %(mkdir -p "#{fetch(:shared_path)}/log")
  command %(chmod g+rx,u+rwx "#{fetch(:shared_path)}/log")

  command %(mkdir -p "#{fetch(:shared_path)}/config")
  command %(chmod g+rx,u+rwx "#{fetch(:shared_path)}/config")

  command %[touch "#{fetch(:shared_path)}/config/puma.rb"]
  command %[touch "#{fetch(:shared_path)}/config/cable.yml"]
  command %[touch "#{fetch(:shared_path)}/config/database.yml"]
  command %[touch "#{fetch(:shared_path)}/config/secrets.yml"]
  command %[touch "#{fetch(:shared_path)}/config/redis.yml"]
  command %[touch "#{fetch(:shared_path)}/config/config.yml"]
  command %[touch "#{fetch(:shared_path)}/config/memcached.yml"]
  command %[touch "#{fetch(:shared_path)}/config/elasticsearch.yml"]
  command %[touch "#{fetch(:shared_path)}/config/secrets.yml"]
  command %(touch "#{fetch(:shared_path)}/config/#{fetch(:application_name)}.conf")

  command %(mkdir -p "#{fetch(:shared_path)}/tmp/pids")
  command %(mkdir -p "#{fetch(:shared_path)}/tmp/sockets")

  command  %(echo "-----> Be sure to edit config files in '#{fetch(:shared_path)}")
end

desc "Deploys the current version to the server."
task :deploy do
  # uncomment this line to make sure you pushed your local branch to the remote origin
  invoke :'git:ensure_pushed'
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    on :launch do
      in_path(fetch(:current_path)) do
        invoke :'sidekiq:restart'
        invoke :'puma:stop'
        invoke :'puma:start'
        command %{mkdir -p tmp/}
        command %{touch tmp/restart.txt}
      end
    end
  end
end

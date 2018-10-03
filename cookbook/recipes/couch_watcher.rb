package 'inotify-tools'

couch_watcher_log_dir = ::File.join(node[:primero][:log_dir], 'couch_watcher')
directory couch_watcher_log_dir do
  action :create
  mode '0755'
  owner node[:primero][:app_user]
  group node[:primero][:app_group]
end

[::File.join(node[:primero][:app_dir], 'tmp/couch_watcher_history.json'),
 ::File.join(node[:primero][:app_dir], 'tmp/couch_watcher_restart.txt'),
 ::File.join(node[:primero][:log_dir], 'couch_watcher/production.log')
].each do |f|
  file f do
    #NOTE: couch_watcher_restart.txt must be 0666 to allow both root and primero to restart
    mode '0666'
    owner node[:primero][:app_user]
    group node[:primero][:app_group]
  end
end

template "#{node[:primero][:app_dir]}/config/couch_watcher.yml" do
  source 'couch_watcher/couch_watcher.yml.erb'
  variables({
    :environments => ['production'],
    :couch_watcher_app_host => node[:primero][:couch_watcher][:app_host],
    :couch_watcher_app_port => node[:primero][:couch_watcher][:app_port]
  })
  owner node[:primero][:app_user]
  group node[:primero][:app_group]
end


couchwatcher_worker_file = "#{node[:primero][:daemons_dir]}/couch-watcher-worker.sh"
file couchwatcher_worker_file do
  mode '0755'
  owner node[:primero][:app_user]
  group node[:primero][:app_group]
  content <<-EOH
#!/bin/bash
#Launch the Couch Watcher
#This file is generated by Chef
cd #{node[:primero][:app_dir]}
source #{::File.join(node[:primero][:home_dir],'.rvm','scripts','rvm')}
RAILS_ENV=#{node[:primero][:rails_env]} RAILS_LOG_PATH=#{couch_watcher_log_dir} bundle exec rails r lib/couch_changes/base.rb
EOH
end

template '/etc/systemd/system/couch_watcher.service' do
  source 'couch_watcher/couch_watcher.service.erb'
end

execute 'Reload Systemd' do
  command 'systemctl daemon-reload'
end

execute 'Enable Couch Watcher' do
  command 'systemctl enable couch_watcher.service'
end

execute 'Reload Couch Watcher' do
  command 'systemctl stop couch_watcher'
end

who_watches_worker_file = "#{node[:primero][:daemons_dir]}/who-watches-the-couch-watcher.sh"

file who_watches_worker_file do
  mode '0755'
  owner node[:primero][:app_user]
  group node[:primero][:app_group]
  content <<-EOH
#!/bin/bash
#Look for any changes to /tmp/couch_watcher_restart.txt.
#When a change occurrs to that file, restart couch-watcher
inotifywait #{::File.join(node[:primero][:app_dir], 'tmp')}/couch_watcher_restart.txt && systemctl restart couch_watcher
EOH
end

template '/etc/systemd/system/who_watches_the_couch_watcher.service' do
  source 'couch_watcher/who_watches_the_couch_watcher.service.erb'
end

execute 'Reload Systemd' do
  command 'systemctl daemon-reload'
end

execute 'Enable Who Watches The Couch Watcher' do
  command 'systemctl enable who_watches_the_couch_watcher.service'
end

execute 'Reload Who Watches The Couch Watcher' do
  command 'systemctl stop who_watches_the_couch_watcher'
end
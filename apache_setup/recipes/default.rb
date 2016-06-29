execute "apt-update" do
    command "apt-get update"
    action :run
    ignore_failure true
end

%w{apache2}.each do |pkg|
    package pkg do
        action :install
    end
end


template "/etc/apache2/sites-enabled/000-default.conf" do
	source "virtual_host.erb"
	variables(:virtual_host => node[:vhost])
end


cookbook_file "/etc/apache2/conf-available/apache_keep_alive.conf" do
    source "apache_keep_alive.conf"
end

execute "enable apache configuration" do
    command "a2enconf apache_keep_alive.conf"
    action :run
end

service "apache2" do
    action :restart
end

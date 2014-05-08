# See <http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/_linux.html>

[Chef::Recipe, Chef::Resource].each { |l| l.send :include, ::Extensions }
Erubis::Context.send(:include, Extensions::Templates)

filename = node.elasticsearch[:rpm_url].split('/').last

remote_file "#{Chef::Config[:file_cache_path]}/#{filename}" do
  source   node.elasticsearch[:rpm_url]
  checksum node.elasticsearch[:rpm_sha]
  mode 00644
end

rpm_package "#{Chef::Config[:file_cache_path]}/#{filename}" do
  action :install
end

bash "chkconfig_elasticsearch" do
	user 'root'
	group 'root'
	code <<-EOF
	/sbin/chkconfig --add elasticsearch
	EOF
	not_if "/sbin/chkconfig --list |grep -q elasticsearch"
end

# Create ES config file
#
template "elasticsearch.yml" do
  path   "#{node.elasticsearch[:path][:conf]}/elasticsearch.yml"
  source "elasticsearch.yml.erb"
  owner node.elasticsearch[:user] and group node.elasticsearch[:user] and mode 0755

  notifies :restart, 'service[elasticsearch]' unless node.elasticsearch[:skip_restart]
end

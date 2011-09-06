#!/usr/bin/ruby
#
# Linode Dynamic DNS Update - github.com/alexwilliamsca
#
# Usage:
#   1. Make sure you create a DNS entry with an A record pointing to your IP.
#   2. Add this script to your crontab (runs every 10 minutes):
#      */10 * * * * bash -c 'source $HOME/.bash_profile && /usr/bin/ruby /opt/linode_dynamic_dns.rb'
#
# The config file ensures you're not constantly hitting Linode with DNS updates.
# Config file (/tmp/.linoderc):
#   dynamic_host: macbook
#   dynamic_domain: yourdomain.com
#   api_key: your-linode-api-key
#
# Notes:
#   If you ever delete/recreate the A record in your DNS, you'll need to change
#   or remove 'dynamic_host_resource_id' from your .linoderc config file

require 'linode'
require 'yaml'

LINODE_CONFIG_FILE = "/tmp/.linoderc"

class LinodeDynDNS
  @@config = YAML.load_file(LINODE_CONFIG_FILE) # chmod 600 /tmp/.linoderc

  def initialize
    @@linode = Linode.new(:api_key => @@config['api_key'])
  end

  def fetch_domain
    this_domain = @@linode.domain.list.find {|domain| domain.domain == @@config['dynamic_domain']}
    return this_domain
  end

  def fetch_domain_id
    unless @@config['domain_id'] then
      @@config['domain_id'] = fetch_domain.domainid
    end
    return @@config['domain_id']
  end

  def fetch_domain_resources
    this_domain_resources = @@linode.domain.resource.list(:DomainID => fetch_domain_id)
    return this_domain_resources
  end

  def fetch_dynamic_name
    this_dynamic_name = fetch_domain_resources.find {|dynamic| dynamic.name == @@config['dynamic_host'] && dynamic.type.casecmp('a')}
    @@config['dynamic_host_resource_id'] = this_dynamic_name.resourceid
    return this_dynamic_name
  end

  def fetch_dynamic_ip
    if @@config['dynamic_host_resource_id'] then
      this_dynamic_resource = @@linode.domain.resource.list(:DomainID => fetch_domain_id, :ResourceID => @@config['dynamic_host_resource_id'])
      this_dynamic_ip = this_dynamic_resource[0].target
    else
      this_dynamic_ip = fetch_dynamic_name.target
    end
    return this_dynamic_ip
  end

  def fetch_public_ip
    @public_ip = %x[curl -s http://ipv4.icanhazip.com].chomp
  end

  def update_dynamic_name_entry
    fetch_public_ip
    unless @@config['dynamic_ip'] == @public_ip then
      # fetch the IP stored in DNS
      dynamic_ip = fetch_dynamic_ip
      @@config['dynamic_ip'] = @public_ip

      if dynamic_ip then
        # if it exists, update it
        result = @@linode.domain.resource.update(:DomainID => fetch_domain_id, :ResourceID => @@config['dynamic_host_resource_id'], :Type => 'A', :Name => @@config['dynamic_host'], :Target => @@config['dynamic_ip'], :TTL_sec => '300')
        if result.resourceid then
          config_file = File.open(LINODE_CONFIG_FILE, "w")
          config_file.puts YAML.dump(@@config)
          config_file.close
          puts "Dynamic DNS entry has been UPDATED"
        end
      end
    else
      puts "DNS is already Up-To-Date"
    end
  end
end

linode = LinodeDynDNS.new
linode.update_dynamic_name_entry
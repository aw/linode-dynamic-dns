#!/usr/bin/ruby
#
# Linode Dynamic DNS Update - github.com/alexwilliamsca
#
# Usage:
#   1. Make sure you create a DNS entry with an A record pointing to your IP
#   2. Run this script without arguments

require 'linode'
require 'yaml'

class LinodeDynDNS
  @@config = YAML.load_file("/tmp/.linoderc") # chmod 600 ~/.linoderc

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
    return this_dynamic_name
  end

  def fetch_dynamic_name_id
    unless @@config['dynamic_host_resource_id'] then
      @@config['dynamic_host_resource_id'] = fetch_dynamic_name.resourceid
    end
    return @@config['dynamic_host_resource_id']
  end

  def fetch_dynamic_ip
    return fetch_dynamic_name.target
  end

  def create_dynamic_name_entry
    result = @@linode.domain.resource.create(:DomainID => this_domain_id, :Type => 'A', :Name => @@config['dynamic_host'], :Target => '49.132.226.172', :TTL_sec => '300')
    p result
    if result.resourceid then
      puts "Dynamic DNS entry has been added"
    end
  end

  def fetch_public_ip
    
  end

  def update_dynamic_name_entry
    # - check if the entry is stored locally
    # - check the public IP using curl
    # - if there's no match, 
  end

end

linode = LinodeDynDNS.new
p linode.fetch_dynamic_ip
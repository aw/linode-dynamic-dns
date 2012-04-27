# Linode Dynamic DNS Update - github.com/alexwilliamsca

## Usage:
  * 1. Install the linode gem: `sudo gem install linode`
  * 2. Make sure you create a DNS entry with an A record pointing to your IP.
  * 3. Add this script to your crontab (runs every 10 minutes):

### Crontab entry
    */10 * * * * bash -c 'source $HOME/.bash_profile && /usr/bin/ruby /opt/linode_dynamic_dns.rb'

## Config file (/opt/.linoderc)

The config file ensures you're not constantly hitting Linode with DNS updates.

    dynamic_host: macbook
    dynamic_domain: yourdomain.com
    api_key: your-linode-api-key

**Make sure you change permissions of /opt/.linoderc to 600**

## Notes:

* If you ever delete/recreate the A record in your DNS, you'll need to change
* or remove 'dynamic_host_resource_id' from your .linoderc config file

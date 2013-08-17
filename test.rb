require 'yaml'
require 'bandcamp_api'
require 'pp'

sensitive = YAML::load File.read './sensitive.yml'

Bandcamp.config.api_key = sensitive[:api_key]

pp Bandcamp.search "tycho"


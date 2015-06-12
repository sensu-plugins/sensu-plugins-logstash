#! /usr/bin/env ruby
#
#   handler-logstash
#
# DESCRIPTION:
#   Designed to take sensu events, transform them into logstah JSON events
#   and ship them to a redis server for logstash to index.  This also
#   generates a tag with either 'sensu-ALERT' or 'sensu-RECOVERY' so that
#   searching inside of logstash can be a little easier.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: diplomat
#
# USAGE:
#
# NOTES:
#   Heavily inspried (er, copied from) the GELF Handler written by
#   Joe Miller.
#
# LICENSE:
#   Zach Dunn @SillySophist http://github.com/zadunn
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-handler'
require 'redis'
require 'json'
require 'socket'
require 'time'

#
# Logstash Handler
#
class LogstashHandler < Sensu::Handler
  def event_name
    @event['client']['name'] + '/' + @event['check']['name']
  end

  def action_to_string
    @event['action'].eql?('resolve') ? 'RESOLVE' : 'ALERT'
  end

  def event_status
    case @event['check']['status']
    when 0
      'OK'
    when 1
      'WARNING'
    when 2
      'CRITICAL'
    else
      'unknown'
    end
  end

  def handle # rubocop:disable all
    time = Time.now.utc.iso8601
    logstash_msg = {
      :@timestamp    => time, # rubocop:disable Style/HashSyntax
      :@version      => 1, # rubocop:disable Style/HashSyntax
      :source        => ::Socket.gethostname, # rubocop:disable Style/HashSyntax
      :tags          => ["sensu-#{action_to_string}"], # rubocop:disable Style/HashSyntax
      :message       => @event['check']['output'], # rubocop:disable Style/HashSyntax
      :host          => @event['client']['name'], # rubocop:disable Style/HashSyntax
      :timestamp     => @event['check']['issued'], # rubocop:disable Style/HashSyntax
      :address       => @event['client']['address'], # rubocop:disable Style/HashSyntax
      :check_name    => @event['check']['name'], # rubocop:disable Style/HashSyntax
      :command       => @event['check']['command'], # rubocop:disable Style/HashSyntax
      :status        => event_status, # rubocop:disable Style/HashSyntax
      :flapping      => @event['check']['flapping'], # rubocop:disable Style/HashSyntax
      :occurrences   => @event['occurrences'], # rubocop:disable Style/HashSyntax
      :action        => @event['action'] # rubocop:disable Style/HashSyntax
    }
    logstash_msg[:type] = settings['logstash']['type'] if settings['logstash'].key?('type')

    case settings['logstash']['output']
    when 'redis'
      redis = Redis.new(host: settings['logstash']['server'], port: settings['logstash']['port'])
      redis.lpush(settings['logstash']['list'], logstash_msg.to_json)
    when 'udp'
      socket = UDPSocket.new
      socket.send(JSON.parse(logstash_msg), 0, settings['logstash']['server'], settings['logstash']['port'])
      socket.close
    end
  end
end

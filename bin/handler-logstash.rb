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

  def handle
    time = Time.now.utc.iso8601
    logstash_msg = {
      :@timestamp    => time,
      :@version      => 1,
      :source        => ::Socket.gethostname,
      :tags          => ["sensu-#{action_to_string}"],
      :message       => @event['check']['output'],
      :host          => @event['client']['name'],
      :timestamp     => @event['check']['issued'],
      :address       => @event['client']['address'],
      :check_name    => @event['check']['name'],
      :command       => @event['check']['command'],
      :status        => event_status,
      :flapping      => @event['check']['flapping'],
      :occurrences   => @event['occurrences'],
      :action        => @event['action']
    }
    logstash_msg[:type] = settings['logstash']['type'] if settings['logstash'].key?('type')

    # merge into the outgoing logstash message (at the top level) any JSON config defined under settings['logstash']['custom']
    logstash_msg = logstash_msg.merge(settings['logstash']['custom']) if settings['logstash'].key?('custom') && !settings['logstash']['custom'].empty?

    settings['logstash']['endpoint'].each do |endpoint|
      case endpoint['output']
      when 'redis'
        redis = Redis.new(host: endpoint['address'], port: endpoint['port'])
        redis.lpush(settings['logstash']['list'], logstash_msg.to_json)
      when 'udp'
        socket = UDPSocket.new
        socket.send(JSON.generate(logstash_msg), 0, endpoint['address'], endpoint['port'])
        socket.close
      when 'tcp'
        socket = TCPSocket.new(endpoint['address'], endpoint['port'])
        socket.puts(JSON.generate(logstash_msg))
        socket.close
      end
    end
  end
end

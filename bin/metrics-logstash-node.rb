#! /usr/bin/env ruby
#
#   metrics-logstash-node
#
# DESCRIPTION:
#   This plugin uses the Logstash node info API to collect metrics, producing a
#   JSON document which is outputted to STDOUT. An exit status of 0 indicates
#   the plugin has successfully collected and produced.
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
#
# USAGE:
#   #YELLOW
#
# NOTES:
#
# LICENSE:
#   Copyright 2011 Sonian, Inc <chefs@sonian.net>
#   Copyright 2018 Philipp Hellmich <phil@hellmi.de>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'rest-client'
require 'json'
require 'base64'

#
# Logstash Node Metrics
#
class LogstashNodeMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to metrics',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.logstash"

  option :host,
         description: 'Logstash server host',
         short: '-h HOST',
         long: '--host HOST',
         default: 'localhost'

  option :port,
         description: 'Logstash monitoring port',
         short: '-p PORT',
         long: '--port PORT',
         proc: proc(&:to_i),
         default: 9600

  option :user,
         description: 'Logstash user',
         short: '-u USER',
         long: '--user USER'

  option :password,
         description: 'Logstash password',
         short: '-P PASS',
         long: '--password PASS'

  option :https,
         description: 'Enables HTTPS',
         short: '-e',
         long: '--https'

  def get_logstash_resource(resource)
    headers = {}
    if config[:user] && config[:password]
      auth = 'Basic ' + Base64.encode64("#{config[:user]}:#{config[:password]}").chomp
      headers = { 'Authorization' => auth }
    end

    protocol = if config[:https]
                 'https'
               else
                 'http'
               end

    r = RestClient::Resource.new("#{protocol}://#{config[:host]}:#{config[:port]}#{resource}", timeout: config[:timeout], headers: headers)
    JSON.parse(r.get)
  rescue Errno::ECONNREFUSED
    warning 'Connection refused'
  rescue RestClient::RequestTimeout
    warning 'Connection timed out'
  end

  def run # rubocop:disable Metrics/AbcSize
    stats = get_logstash_resource('/_node/stats')

    timestamp = Time.now.to_i
    node = stats

    metrics = {}
    metrics['jvm.threads.count'] = node['jvm']['threads']['count']
    metrics['jvm.mem.heap_used_in_bytes'] = node['jvm']['mem']['heap_used_in_bytes']
    metrics['jvm.mem.heap_used_percent'] = node['jvm']['mem']['heap_used_percent']
    metrics['jvm.mem.non_heap_used_in_bytes'] = node['jvm']['mem']['non_heap_used_in_bytes']
    metrics['jvm.gc.collectors.old.collection_time_in_millis'] = node['jvm']['gc']['collectors']['old']['collection_time_in_millis']
    metrics['jvm.gc.collectors.young.collection_time_in_millis'] = node['jvm']['gc']['collectors']['young']['collection_time_in_millis']
    metrics['jvm.gc.collectors.old.collection_count'] = node['jvm']['gc']['collectors']['old']['collection_count']
    metrics['jvm.gc.collectors.young.collection_count'] = node['jvm']['gc']['collectors']['young']['collection_count']

    metrics['process.open_file_descriptors'] = node['process']['open_file_descriptors']
    metrics['process.peak_open_file_descriptors'] = node['process']['peak_open_file_descriptors']
    metrics['process.max_file_descriptors'] = node['process']['max_file_descriptors']

    # logstash < 6.0
    if node.key?('pipeline')
      node['pipeline']['events'].each do |key, value|
        metrics["pipeline.events.#{key}"] = value
      end

      node['pipeline']['plugins']['inputs'].each do |item|
        item['events'] = {} unless item.key?('events')
        metrics["pipeline.plugins.inputs.#{item['name']}.#{item['id']}.events.in"] = item['events']['in'].to_i || 0
        metrics["pipeline.plugins.inputs.#{item['name']}.#{item['id']}.events.out"] = item['events']['out'].to_i || 0
        metrics["pipeline.plugins.inputs.#{item['name']}.#{item['id']}.events.queue_push_duration_in_millis"] = \
          item['events']['queue_push_duration_in_millis'].to_i || 0
      end

      node['pipeline']['plugins']['filters'].each do |item|
        metrics["pipeline.plugins.filters.#{item['name']}.#{item['id']}.events.out"] = item['events']['out'].to_i || 0
        metrics["pipeline.plugins.filters.#{item['name']}.#{item['id']}.events.duration_in_millis"] = item['events']['duration_in_millis'].to_i || 0
        metrics["pipeline.plugins.filters.#{item['name']}.#{item['id']}.matches"] = item['matches'].to_i if item.key?('matches')
      end

      node['pipeline']['plugins']['outputs'].each do |item|
        item['events'] = {} unless item.key?('events')
        metrics["pipeline.plugins.outputs.#{item['name']}.#{item['id']}.events.in"] = item['events']['in'].to_i || 0
        metrics["pipeline.plugins.outputs.#{item['name']}.#{item['id']}.events.out"] = item['events']['out'].to_i || 0
        metrics["pipeline.plugins.outputs.#{item['name']}.#{item['id']}.events.duration_in_millis"] = item['events']['duration_in_millis'].to_i || 0
      end
    # logstash >= 6.0
    elsif node.key?('pipelines')
      node['pipelines'].each_key do |pipeline|
        if node['pipelines'][pipeline]['events'].nil? || node['pipelines'][pipeline]['events'] == 'null'
          # Skip
        else
          node['pipelines'][pipeline]['events'].each do |key, value|
            metrics["pipelines.#{pipeline}.events.#{key}"] = value
          end
        end

        node['pipelines'][pipeline]['plugins']['inputs'].each do |item|
          item['events'] = {} unless item.key?('events')
          metrics["pipelines.#{pipeline}.plugins.inputs.#{item['name']}.#{item['id']}.events.in"] = item['events']['in'].to_i || 0
          metrics["pipelines.#{pipeline}.plugins.inputs.#{item['name']}.#{item['id']}.events.out"] = item['events']['out'].to_i || 0
          metrics["pipelines.#{pipeline}.plugins.inputs.#{item['name']}.#{item['id']}.events.queue_push_duration_in_millis"] = item['events']['queue_push_duration_in_millis'].to_i || 0 # rubocop:disable Metrics/LineLength
        end

        node['pipelines'][pipeline]['plugins']['filters'].each do |item|
          item['events'] = {} unless item.key?('events')
          metrics["pipelines.#{pipeline}.plugins.filters.#{item['name']}.#{item['id']}.events.in"] = item['events']['in'].to_i || 0
          metrics["pipelines.#{pipeline}.plugins.filters.#{item['name']}.#{item['id']}.events.out"] = item['events']['out'].to_i || 0
          metrics["pipelines.#{pipeline}.plugins.filters.#{item['name']}.#{item['id']}.events.duration_in_millis"] = item['events']['duration_in_millis'].to_i || 0 # rubocop:disable Metrics/LineLength
          metrics["pipelines.#{pipeline}.plugins.filters.#{item['name']}.#{item['id']}.matches"] = item['matches'].to_i if item.key?('matches')
        end

        node['pipelines'][pipeline]['plugins']['outputs'].each do |item|
          item['events'] = {} unless item.key?('events')
          metrics["pipelines.#{pipeline}.plugins.outputs.#{item['name']}.#{item['id']}.events.in"] = item['events']['in'].to_i || 0
          metrics["pipelines.#{pipeline}.plugins.outputs.#{item['name']}.#{item['id']}.events.out"] = item['events']['out'].to_i || 0
          metrics["pipelines.#{pipeline}.plugins.outputs.#{item['name']}.#{item['id']}.events.duration_in_millis"] = item['events']['duration_in_millis'].to_i || 0 # rubocop:disable Metrics/LineLength
        end
      end
    end

    metrics.each do |k, v|
      output([config[:scheme], k].join('.'), v, timestamp)
    end
    ok
  end
end

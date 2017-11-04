require_relative './spec_helper.rb'
require_relative '../bin/metrics-logstash-node.rb'

describe 'MetricsLogstash', '#run' do
  before(:all) do
    LogstashNodeMetrics.class_variable_set(:@@autorun, nil)
  end

  it 'accepts config' do
    args = %w(--user foo --password bar)
    check = LogstashNodeMetrics.new(args)
    expect(check.config[:password]).to eq 'bar'
  end

  it 'returns metrics data' do
    stub_request(:get, /_node\/stats/)
      .with(basic_auth: %w(foo bar))
      .to_return(
        status: 200,
        headers: {
          'Content-Type' => 'application/json'
        },
        body: File.new('test/fixtures/node_stats.json')
      )
    args = %w(--user foo --password bar --host localhost --port 4200 --scheme node01.logstash)

    check = LogstashNodeMetrics.new(args)
    expect { check.run }.to output(
      /node01.logstash.pipeline.plugins.inputs.tcp.4a3d87d316c088c052271a51fae0e37f47a193b9-30.events.queue_push_duration_in_millis 1162712/
    ).to_stdout.and raise_error(SystemExit)
  end

  it 'returns output duration data' do
    stub_request(:get, /_node\/stats/)
      .with(basic_auth: %w(foo bar))
      .to_return(
        status: 200,
        headers: {
          'Content-Type' => 'application/json'
        },
        body: File.new('test/fixtures/node_stats.json')
      )
    args = %w(--user foo --password bar --host localhost --port 4200 --scheme node01.logstash)

    check = LogstashNodeMetrics.new(args)
    expect { check.run }.to output(
      /node01.logstash.pipeline.plugins.outputs.elasticsearch4a3d87d316c088c052271a51fae0e37f47a193b9-33.events.duration_in_millis 24613/
    ).to_stdout.and raise_error(SystemExit)
  end
end

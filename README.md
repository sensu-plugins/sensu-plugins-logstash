## Sensu-Plugins-logstash

[ ![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-logstash.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-logstash)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-logstash.svg)](http://badge.fury.io/rb/sensu-plugins-logstash)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-logstash/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-logstash)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-logstash/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-logstash)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-logstash.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-logstash)

## Functionality

## Files
 * bin/handler-logstash

## Usage

**handler-logstash**
```
{
  "logstash": {
    "server": "redis.example.tld",
    "port": 6379,
    "list": "logstash",
    "type": "sensu-logstash",
    "output": "redis"
  }
}
```

Supported output types: `redis`, `tcp`, `udp`

## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)

## Notes

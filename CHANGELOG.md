#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]
### Added
- metrics-logstash-node.rb: Added queue_push_duration_in_millis metric for logstash pipeline inputs. (@Evesy)

## [1.1.1] - 2017-08-26
### Fixed
- locking runtime dependency and misc changes to `metrics-logstash-node.rb` (@multani)


## [1.1.0] - 2017-07-27
## Added
- test with ruby 2.4 as sensu now ships with it. (@majormoses)
- metrics-logstash-node.rb: new check to collect metrics via the logstash api (@runningman84)

## [1.0.0] - 2017-05-29
### Added
- testing on ruby 2.3

### Breaking Changes
- dropped ruby 1.9 support
- Added support to send to multiple endpoints

## [0.1.1] - 2017-03-15
- changed json dependency from '= 1.8.3' to '< 2.0.0'

## [0.1.1] - 2017-03-15
- changed json dependency from '= 1.8.3' to '< 2.0.0'
- handler-logstash.rb now merges value of `custom` attribute into
  outgoing messages, if provided.

## [0.1.0] - 2016-08-10
- changed sensu-plugin dependecy from `= 1.2.0` to `~> 1.2`
- added TCP socket as an output option

## [0.0.4] - 2015-09-29
- fixed JSON generation for UDP in handler-logstash.rb

## [0.0.3] - 2015-07-14
### Changed
- updated documentation links
- general gem cleanup

## [0.0.2] - 2015-06-03
### Changed
- updated sensu-plugin gem to 1.2.0

## 0.0.1 - 2015-05-29
### Added
- initial release

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-logstash/compare/1.1.1...HEAD
[1.1.1]: https://github.com/sensu-plugins/sensu-plugins-logstash/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/sensu-plugins/sensu-plugins-logstash/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-logstash/compare/0.1.1...1.0.0
[0.1.1]: https://github.com/sensu-plugins/sensu-plugins-logstash/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/sensu-plugins/sensu-plugins-logstash/compare/0.0.4...0.1.0
[0.0.4]: https://github.com/sensu-plugins/sensu-plugins-logstash/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/sensu-plugins/sensu-plugins-logstash/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/sensu-plugins/sensu-plugins-logstash/compare/0.0.1...0.0.2

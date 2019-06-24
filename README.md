# AppStatus

AppStatus is a Rails engine which makes it easy to expose application status
data in a way easily consumed by Nagios or other monitoring packages.

## Build Status

[![Build Status](https://travis-ci.org/alexdean/app_status.svg?branch=master)](https://travis-ci.org/alexdean/app_status)

## Why?

Defining health checks outside of your application (like in Nagios)
has a few different problems.

  1. The people who maintain nagios aren't necessarily
     the same people who maintain the application.
  1. Keeping the 2 systems in sync can be non-trivial with a fast-changing
     application.
  1. Failing to monitor new features, or monitoring the wrong things, leads
     to a false sense of security.

Instead, app_status lets you define your health checks right in the application
itself and expose the results as a JSON service which is easy for Nagios
to consume.

The benefits basically come down to 1 major thing: Nagios doesn't need to know
anything about your application. All Nagios needs is a 'healthy/not healthy'
status report.

This is good because:

  1. As your app's feature set changes, you can deploy updated health checks
     at the same time. No need for coordinated updates between the app and
     the monitoring system.
  1. Credentials for external services (like databases) can stay with your
     app. Nagios doesn't need them.
  1. You don't need nrpe to do local process checks. Your application can do
     them for itself.
  1. Your health checks can be testable methods just like all your other code.
  1. You don't need to duplicate complex queries & other business logic over
     to Nagios.

## Installation

### `Gemfile`

```ruby
gem 'app_status'
```

### `config/routes.rb`

```ruby
mount AppStatus::Engine => "/status(.:format)", defaults: {format: 'json'}
```

This exposes `http://localhost:3000/status.json`. (Support for HTML output was
dropped in v2.0. see [PR #3](https://github.com/alexdean/app_status/pull/3).)

### `config/initializers/app_status.rb`

This is where you set up the checks which you want to be run when
someone hits the URL above. Set up some calls which evaluate the health
of your application and call `add_check` for each one.

#### add_check

`add_check` expects a service name, plus a block to be evaluated to determine
the health of that service. The block should return either a status value, or
a 2-element array with status and some details.

```ruby
AppStatus::CheckCollection.configure do |c|

  c.add_check('some_service') do
    details = do_something_to_check_your_service
    status = (details != "FAIL") ? :ok : :critical
    [status, details]
  end

  c.add_check('failing_service') do
    :critical # you can return just a status if desired.
  end
end
```

The details string should be concise. `app_status` does its best to provide
readable output, and Nagios does its best to make this impossible to actually
do well.

Valid status values (in ascending order of seriousness) are:
  - :ok
  - :warning
  - :critical
  - :unknown

These are set up to be compatible with Nagios.

#### add_description

`add_description` allows you to specify extended description and troubleshooting
information for any check which has been added via `add_check`.

These descriptions are not included in the `status.json` payload by default.
Add `?descriptions=1` to include them.

```ruby
AppStatus::CheckCollection.configure do |c|

  c.add_check('some_service') do
    [:critical, 'what is going on']
  end
  c.add_description 'some_service', <<-EOF
some_service failures indicate that some_service is going wrong.

this is handy since nagios really requires brief output, but sometimes you need
more space to explain what a check is.

think of it as the answer to the problem of "That guy is on vaction, but his
app is raising alarms. WTF do I do?"
  EOF

end
```

Keep in mind that anyone who hits your status URL can cause your checks to run,
so if they expose sensitive data or are a potential DOS vector you should
probably protect them with some kind of authentication.

## Built-In Checks

As of version 2.0.0, app_status started including a set of built-in checks
which can be installed. Have a look in
[`lib/app_status/checks`](https://github.com/alexdean/app_status/tree/master/lib/app_status/checks)
for a full list.

### `ruby_version` check

Verifies that the running version of ruby is as expected.

Default is to read the expected version from a `.ruby-version` file in the
rails root directory.

```ruby
# config/initializers/app_status.rb
require 'app_status/checks/ruby_version'
AppStatus::Checks::RubyVersion.install!
```

If you wish to specify the expected version string by another method, that's
also supported.

```ruby
# config/initializers/app_status.rb
require 'app_status/checks/ruby_version'
AppStatus::Checks::RubyVersion.install!(expected_version: '2.5.0')
```

## Usage

`$ curl -H 'Accept: application/json' http://localhost:3000/status`

Output will look something like this:
```json
{
  "status": "critical",
  "status_code": 2,
  "ms": 52,
  "finished": "2013-10-03T21:28:10Z",
  "checks": {
    "some_service": {
      "status": "ok",
      "status_code": 0,
      "details": "Looks good!",
      "ms": 30
    },
    "failing_service": {
      "status": "critical",
      "status_code": 2,
      "details": "",
      "ms": 20
    }
  }
}
```

The overall status will be the worst value observed in your individual checks.

## Nagios Integration

[check_app_status.rb](check_app_status.rb)
is a Nagios check script which can be used to monitor the output from `app_status`

```
$ ./check_app_status.rb --help
Nagios check script for app_status. See https://github.com/alexdean/app_status
    -v, --verbose                    Output more information
    -V, --version                    Output version information
    -h, --help                       Display this screen
    -u, --url VAL                    Url to monitor
    -a, --auth VAL                   HTTP basic auth in the form 'user:password'
    -t, --timeout VAL                Timeout after waiting this long for a response.
```

The script's exit status is derived from the overall status returned by the
server. Individual detail items will be grouped by status for display.
(Unknowns are displayed together, then criticals, then warnings, then OKs.)

Sample output

```
$ ./check_app_status.rb --url http://localhost:3000/status

CRIT failed_service
--- failed_service: shit's on fire yo, 501ms

WARN problematic_service
--- problematic_service: not looking good, 2001ms

OK ok_process, ok_process_2
--- ok_process: these are some details, 0ms
--- ok_process_2: more details on another process, 0ms
```

# AppStatus

AppStatus is a Rails engine which makes it easy to expose application status
data in a way easily consumed by Nagios or other monitoring packages.

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

Wire it up.

```ruby
mount AppStatus::Engine, at: "/status"
```

This exposes the following URLs
  - `http://localhost:3000/status`
    renders html or json according to Accept headers. Defaults to JSON.
  - `http://localhost:3000/status/index.json`
  - `http://localhost:3000/status/index.html` <-- fugly


### `config/initializers/app_status.rb`

This is where you set up the checks which you want to be run when
someone hits the URL above. Set up some calls which evaluate the health
of your application and call `add` for each one.

```ruby
AppStatus::CheckCollection.configure do |c|
  value = some_service_check
  c.add(:name => 'some_service', :status => :ok, :details => value)
end
```

The checks that you set up here are not run when you configure them. They're
run whenever someone hits the check URL.

Status values (in ascending order of seriousness)
  - :ok
  - :warning
  - :critical
  - :unknown

These are set up to be compatible with Nagios.

Details doesn't have to be a string. It can be anything which is serializable
as JSON.

## Usage

`$ curl -H 'Accept: application/json' http://localhost:3000/status`

Output will look something like this:
```json
{
  "status": "critical",
  "status_code": 2,
  "run_time_ms": 52,
  "finished": "2013-10-03T21:28:10Z",
  "checks": {
    "some_service": {
      "status": "ok",
      "status_code": 0,
      "details": "Looks good!"
    },
    "failing_service": {
      "status": "critical",
      "status_code": 2,
      "details": "Oh noes!"
    }
  }
}
```

The overall status will be the worst status which is actually observed in your
individual checks.

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

CRIT   failed_service         shit's on fire, yo.
---------------------------------------------------
WARN   problematic_service    not looking good
WARN   questionable_service   probably needs a look
---------------------------------------------------
OK     functional_service     happy!
---------------------------------------------------
                                               0 ms
```

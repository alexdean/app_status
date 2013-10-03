# AppStatus

AppStatus is a Rails engine which makes it easy to expose application status
data in a way easily consumed by Nagios or other monitoring packages.

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
  "details": {
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

`run_time` is in milliseconds.
## v1.2.0 14 Oct, 2013

  - use main app's default layout for html status report
  - we now support urls like `/status.json` or `/status.html`

recommended mount is now:

```ruby
mount AppStatus::Engine => "/status(.:format)", defaults: {format: 'json'}
```

https://github.com/alexdean/app_status/compare/v1.1.2...v1.2.0

## v1.1.2 09 Oct, 2013

  - include url to html status report in json output
  - render this url in `check_app_status.rb`
  - bugfixes in html report

https://github.com/alexdean/app_status/compare/v1.1.1...v1.1.2

## v1.1.1 09 Oct, 2013

  - routing fix for rails 4.

https://github.com/alexdean/app_status/compare/v1.1.0...v1.1.1

## v1.1.0 08 Oct, 2013

  - add `add_description` for more verbose information about a check
  - remove haml
  - remove rails version requirement. should work with any rails

https://github.com/alexdean/app_status/compare/v1.0.0...v1.1.0

## v1.0.0 06 Oct, 2013

  - replace `add` with `add_check`
  - better validation of checks at startup time
  - report per-check execution times
  - if a check is mis-configured, report it in output instead of raising
    an error.

https://github.com/alexdean/app_status/compare/v0.1.1...v1.0.0

## v0.1.1 04 Oct, 2013

  - bug fixes

https://github.com/alexdean/app_status/compare/v0.1.0...v0.1.1

## v0.1.0 04 Oct, 2013

  - initial release
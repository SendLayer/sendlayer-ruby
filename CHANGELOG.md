# Changelog

All notable changes to this project are documented in this file.

## [1.1.0](https://github.com/sendlayer/sendlayer-ruby/compare/v1.0.0...v1.1.0) (2026-08-25)

Brings the Ruby SDK to parity with the PHP, Python and Node.js 1.1.0 releases.

### Bug Fixes

* Typed exceptions are no longer flattened to the base class. `make_request`
  called `handle_response` *inside* its own `begin`/`rescue`, so the
  `SendLayerAuthenticationError` (and every other typed error) raised there was
  caught by the broad `rescue => e` and re-raised as
  `SendLayerError.new("Network error: ...")`. Rescuing
  `SendLayerAuthenticationError` could never match. Only the transport call is
  guarded now.
* `Emails#send` no longer discards the plain-text body when both `text` and
  `html` are supplied. The payload used an `if`/`else` that could only ever emit
  one of the two fields. Both `HTMLContent` and `PlainContent` are now sent, and
  `ContentType` is reported as `HTML` whenever an HTML body is present.
* API error messages are no longer discarded. The client read
  `error_data['Error']`, but SendLayer returns errors as
  `{"Errors": [{"Code": ..., "Message": ...}]}`, so every error surfaced a
  hardcoded default instead of the API's own text. The 401 branch did not read
  the response body at all. Multiple messages are joined with `; `.
* Non-JSON error bodies no longer raise `JSON::ParserError` out of the SDK. An
  HTML error page from a proxy now falls back to the HTTP reason phrase.
* Undecodable *success* bodies now raise `SendLayerError` instead of
  `JSON::ParserError`, which is not a `SendLayerError` and so escaped callers
  rescuing the base type.
* Connections now time out. `read_timeout` was set but `open_timeout` was not,
  so a connection that never completed its handshake could hang past the
  configured timeout.
* Content consisting of an empty string is now rejected by validation, which
  previously checked only for `nil` and would send an email with no body.

### Features

* Every exception now carries `status_code`, `response` and `errors`, along with
  a `codes` helper for branching on SendLayer's numeric error codes. These
  previously existed only on `SendLayerAPIError`, so reading them after
  rescuing `SendLayerError` raised `NoMethodError` for every other type.
* Added a `:headers` option for extra request headers. They are applied before
  `Authorization`, so a caller cannot accidentally drop authentication.
* `Client::ERROR_MAP` replaces the hand-rolled `case` chain, so status-to-error
  mapping is declared in one place.

### Documentation

* Documented the exception attributes, the full exception table, the
  `SendLayerAPIError` message prefix, and the 30-second default timeout.
* Added a Configuration section and an explicit HTML-with-plain-text-fallback
  example.

### Breaking Changes

* `500` maps to `SendLayerInternalServerError`, but other 5xx statuses
  (502, 503, 504) now raise `SendLayerAPIError` rather than
  `SendLayerInternalServerError`. This matches the Python and Node.js SDKs.
  Rescue `SendLayerError` to catch both.
* Passing `text: ''` or `html: ''` as the only content now raises
  `SendLayerValidationError`.
* `SendLayerError#message` is no longer backed by an `attr_reader`. It is
  inherited from `StandardError`, so `e.message` behaves as before.

## 1.0.0

* Initial public release.

# Changelog
All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.2] - 2021-08-30
### Added
- Thread protection when adding an entry to the watched URLs array

## [1.3.0] - 2020-05-19
### Changed
- SFSMonitor was forked from https://github.com/daniel-pedersen/SKQueue
- Updated from kevents to Dispatch Source by using Apple's Directory Monitor
- See https://stackoverflow.com/a/61035069/10327858
- Added static variables to help keep the number of file descriptors under the OS maximum
- Additional functions and callbacks
- Paths changes to URLs
- Updated README

## [1.2.0] - 2018-09-27
### Added
- Swift 4 support.
- `Unlock` event notification, for files being unlocked by the `funlock` syscall.
- `DataAvailable` event notification, to test for `EVFILT_READ` activation.
- This changelog.

### Removed
- Logging to the system console.

## [1.1.0] - 2017-04-25
### Added
- Method `fileDescriptorForPath` in `SKQueue`.
- Optional `delegate` parameter to the `SKQueue` initializer.

## [1.0.0] - 2017-04-10
### Changed
- API follows the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).

### Removed
- An overloaded `receivedNotification` in the `SKQueueDelegate` protocol which accepts notification as a string.

## [0.9.0] - 2017-04-10
### Added
- Swift package manager support.

[1.2.0]: https://github.com/daniel-pedersen/SKQueue/tree/v1.2.0
[1.1.0]: https://github.com/daniel-pedersen/SKQueue/tree/v1.1.0
[1.0.0]: https://github.com/daniel-pedersen/SKQueue/tree/v1.0.0
[0.9.0]: https://github.com/daniel-pedersen/SKQueue/tree/v0.9.0

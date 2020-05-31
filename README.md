# SFSMonitor
Swift File System Monitor is a Swift 5 library used to monitor changes to the filesystem.
It is based on the convenient APIs from Daniel Pederson's [SKQueue](https://github.com/daniel-pedersen/SKQueue) but replaces kevent with Dispatch Source as the means for monitoring changes. The mechanism is similar to Apple's own Directory Monitor (reference to which can be found [here](https://stackoverflow.com/a/61035069/10327858)), but SFSMonitor gives a complete API for maintaining a whole queue of watched files and folders.

## Requirements
* Swift 5
* Swift tools version 4

## Installation

### Swift Package Manager
To add SFSMonitor to your Xcode project, simply add a Swift Package with the address 
```swift
https://github.com/ClassicalDude/SFSMonitor.git
```

## Usage
To monitor the filesystem with `SFSMonitor`, you first need a `SFSMonitorDelegate` instance that can accept notifications.

The class behaves as a singleton class. Since it manages limited OS resources, all class instances will refer to the same static constants, variables and dictionaries.

URLs to watch can then be added with `addUrl`, as per the example below. The `addUrl` method returns an integer value: 0 for success, 1 if the URL is already monitored, 2 if maximum number of monitored files and directories is reached, 3 for general error.

Note: iOS, iPadOS and MacOS all have a limit on how many files and directories can be opened simultaneously, even just for the purpose of monitoring. That number includes all files used by your app, and as of iOS and iPadOS 13, and MacOS Catalina, it is set to 256 files. For more details, please read [here](https://wilsonmar.github.io/maximum-limits/).
SFSMonitor has a limit set at 224 files and directories, which can be changed by altering the static variable SFSMonitor.maxMonitored.

The code is well documented - please go through it for more details and methods.

### Example
```swift
import SFSMonitor

class SomeClass: SFSMonitorDelegate {
  func receivedNotification(_ notification: SFSMonitorNotification, url: URL, queue: SFSMonitor) {
  print("\(notification.toStrings().map { $0.rawValue }) @ \(url.path)")
  }
}

let delegate = SomeClass()
let queue = SFSMonitor(delegate: delegate)
SFSMonitor.maxMonitored = 200

_ = queue.addURL(URL(fileURLWithPath: "/Users/steve/Documents"))
let test = queue.addURL(URL(fileURLWithPath: "/Users/steve/Documents"))
if test == 1 {
  print("The URL has already been added to the queue")
}
_ = queue.addURL(URL(fileURLWithPath: "/Users/steve/Documents/dog.jpg"))
```
|                       Action                        |                         Sample output                         |
|:---------------------------------------------------:|:-------------------------------------------------------------:|
|   Add or remove file in `/Users/steve/Documents`    |             `["Write"] @ /Users/steve/Documents`              |
| Add or remove directory in `/Users/steve/Documents` |     `["Write", "SizeIncrease"] @ /Users/steve/Documents`      |
|   Write to file `/Users/steve/Documents/dog.jpg`    | `["Rename", "SizeIncrease"] @ /Users/steve/Documents/dog.jpg` |

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

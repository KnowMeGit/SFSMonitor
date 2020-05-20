//
//  SFSMonitor.swift
//  Forked from https://github.com/daniel-pedersen/SKQueue
//  Updated from kevents to Dispatch Source by using Apple's Directory Monitor
//  See https://stackoverflow.com/a/61035069/10327858
//
//  Created by Ron Regev on 18/05/2020.
//  Copyright © 2020 Ron Regev. All rights reserved.
//

import Foundation

/// A protocol that allows delegates of `SFSMonitor` to respond to changes in a directory or of a specific file.
public protocol SFSMonitorDelegate {
    func receivedNotification(_ notification: SFSMonitorNotification, url: URL, queue: SFSMonitor)
}

/// A string representation of possible changes detected by SFSMonitor.
public enum SFSMonitorNotificationString: String {
    case Rename
    case Write
    case Delete
    case AttributeChange
    case SizeIncrease
    case LinkCountChange
    case AccessRevocation
    case Unlock
    case DataAvailable
}

/// An OptionSet of possible changes detected by SFSMonitor.
public struct SFSMonitorNotification: OptionSet {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let None             = SFSMonitorNotification([])
    public static let Rename           = SFSMonitorNotification(rawValue: UInt32(NOTE_RENAME))
    public static let Write            = SFSMonitorNotification(rawValue: UInt32(NOTE_WRITE))
    public static let Delete           = SFSMonitorNotification(rawValue: UInt32(NOTE_DELETE))
    public static let AttributeChange  = SFSMonitorNotification(rawValue: UInt32(NOTE_ATTRIB))
    public static let SizeIncrease     = SFSMonitorNotification(rawValue: UInt32(NOTE_EXTEND))
    public static let LinkCountChange  = SFSMonitorNotification(rawValue: UInt32(NOTE_LINK))
    public static let AccessRevocation = SFSMonitorNotification(rawValue: UInt32(NOTE_REVOKE))
    public static let Unlock           = SFSMonitorNotification(rawValue: UInt32(NOTE_FUNLOCK))
    public static let DataAvailable    = SFSMonitorNotification(rawValue: UInt32(NOTE_NONE))
    public static let Default          = SFSMonitorNotification(rawValue: UInt32(INT_MAX))
  
    /// A method to convert the SFSMonitor OptionSet to String.
    public func toStrings() -> [SFSMonitorNotificationString] {
        var s = [SFSMonitorNotificationString]()
        if contains(.Rename)           { s.append(.Rename) }
        if contains(.Write)            { s.append(.Write) }
        if contains(.Delete)           { s.append(.Delete) }
        if contains(.AttributeChange)  { s.append(.AttributeChange) }
        if contains(.SizeIncrease)     { s.append(.SizeIncrease) }
        if contains(.LinkCountChange)  { s.append(.LinkCountChange) }
        if contains(.AccessRevocation) { s.append(.AccessRevocation) }
        if contains(.Unlock)           { s.append(.Unlock) }
        if contains(.DataAvailable)    { s.append(.DataAvailable) }
        return s
    }
}

public class SFSMonitor {
    // MARK: Properties
    /// The maximal number of file descriptors allowed to be opened. On iOS and iPadOS it is recommended to be kept under 224 (allowing 32 more for the app).
    public static var maxMonitored : Int = 223
    
    /// A counter of the items added to the SFSMonitor queue throughout all instances of SFSMonitor. Cannot exceed maxMonitored.
    private static var globalCounter : Int = -1
    
    /// A dictionary of SFSMonitor watched URLs and their Dispatch Sources.
    private var watchedUrls : [URL : DispatchSource] = [:]
    
    public var delegate: SFSMonitorDelegate?

    // MARK: Initializers
    public init?(delegate: SFSMonitorDelegate? = nil) {
        self.delegate = delegate
    }

    deinit {
        removeAllURLs()
    }
    
    // MARK: Add URL to the queue
    /// Add a URL to the queue of files and folders monitored by SFSMonitor. Return values: 0 for success, 1 if the URL is already monitored, 2 if maximum number of monitored files and directories is reached, 3 for general error.
    public func addURL(_ url: URL, notifyingAbout notification: SFSMonitorNotification = SFSMonitorNotification.Default) -> Int {
        
        // Check if this URL is not already present
        if watchedUrls.keys.contains(url) {
            //print ("SFSMonitor error: trying to add a monitored URL to queue: \(url)")
            return 1
        }
        
        // Check if the number of open file descriptors exceeds the limit
        if SFSMonitor.globalCounter > SFSMonitor.maxMonitored {
            //print ("SFSMonitor error: number of allowed file descriptors exceeded")
            return 2
        }
        
        // Increment the global counter
        SFSMonitor.globalCounter += 1
        
        // Define the DispatchQueue
        let SFSMonitorQueue =  DispatchQueue(label: "sfsmonitor", attributes: .concurrent)
        
        // Open the file or directory referenced by URL for monitoring only.
        let fileDescriptor = open((url as NSURL).fileSystemRepresentation, O_EVTONLY)
        
        // Define a dispatch source monitoring the file or directory for additions, deletions, and renamings.
        if let SFSMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: DispatchSource.FileSystemEvent.all, queue: SFSMonitorQueue) as? DispatchSource {
            
            // Define the block to call when a file change is detected.
            SFSMonitorSource.setEventHandler {
                // Call out to the `SFSMonitorDelegate` so that it can react appropriately to the change.
                let event = SFSMonitorSource.data as DispatchSource.FileSystemEvent
                let notification = SFSMonitorNotification(rawValue: UInt32(event.rawValue))
                self.delegate?.receivedNotification(notification, url: url, queue: self)
                //print ("SFSMonitor notification: \(notification.toStrings())")
                //print ("Number of file descriptors open: \(SFSMonitor.globalCounter)")
            }
        
            // Define a cancel handler to ensure the directory is closed when the source is cancelled.
            SFSMonitorSource.setCancelHandler {
                close(fileDescriptor)
                self.watchedUrls.removeValue(forKey: url)
                
                // Reduce global counter
                SFSMonitor.globalCounter -= 1
                //print ("SFSMonitor stopped watching the URL \(url)")
                //print ("Number of file descriptors open: \(SFSMonitor.globalCounter)")
            }
            
            // Start monitoring
            SFSMonitorSource.resume()
        
            // Populate our watched URL array
            watchedUrls[url] = SFSMonitorSource
            
        } else { return 3 } // Something went wrong
        
        return 0
        
    }

    /// A boolean value that indicates if the entered URL is already being monitored by SFSMonitor.
    public func isURLWatched(_ url: URL) -> Bool {
        return watchedUrls.keys.contains(url)
    }

    /// Remove the entered URL from the SFSMonitor queue and close its file reference.
    public func removeURL(_ url: URL) {
        if let SFSMonitorSource = watchedUrls[url] {
            
            // Cancel dispatch source and remove it from list
            SFSMonitorSource.cancel()
        }
    }

    /// Reset the SFSMonitor queue for this instance of the class.
    public func removeAllURLs() {
        watchedUrls.forEach { watchedUrl in
            watchedUrl.value.cancel()
        }
        watchedUrls = [:]
    }

    /// The number of URLs being watched by this instance of SMSMonitor.
    public func numberOfWatchedURLsForQueue() -> Int {
        return watchedUrls.count
    }
    
    /// The number of URLs being watched by all instances of SMSMonitor.
    public func globalNumberOfWatchedUrls() -> Int {
        return SFSMonitor.globalCounter+1
    }
    
    /// An array of all URLs being watched by this instance of SMSMonitor.
    public func URLsWatched() -> [URL] {
        return Array(watchedUrls.keys)
    }
}



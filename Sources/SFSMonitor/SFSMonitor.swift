//
//  SFSMonitor.swift
//  Forked from https://github.com/daniel-pedersen/SKQueue
//  Updated from kevents to Dispatch Source by using Apple's Directory Monitor
//  See https://stackoverflow.com/a/61035069/10327858
//
//  Created by Michael Redig 11/16/2022
//

import Foundation

/// A protocol that allows delegates of `SFSMonitor` to respond to changes in a directory or of a specific file.
public protocol SFSMonitorDelegate {
    func receivedNotification(_ notification: SFSMonitorNotification, url: URL, queue: SFSMonitor)
}

public class SFSMonitor {
    // MARK: Properties
    // The maximal number of file descriptors allowed to be opened. On iOS and iPadOS it is recommended to be kept at 224 or under (allowing 32 more for the app).
    private static var maxMonitored : Int = 224
    
    // A dictionary of SFSMonitor watched URLs and their Dispatch Sources for all class instances.
    private static var watchedURLs : [URL : DispatchSource] = [:]
    
    // Define the DispatchQueue
    private let SFSMonitorQueue =  DispatchQueue(label: "sfsmonitor", attributes: .concurrent)
    
    // DispatchQueue for thread safety when modifying the watchedURLs array
    private let SFSThreadSafetyQueue = DispatchQueue(label: "sfsthreadqueue", qos: .utility)
    
    public var delegate: SFSMonitorDelegate?

    // MARK: Initializers
    public init(delegate: SFSMonitorDelegate? = nil) {
        self.delegate = delegate
    }
    
    // Note: if deinit is used to release the resources, they will be released unexpectedly. You have to call removeAllURLs() manually to do that.
    
    // MARK: Add URL to the queue
    /// Add a URL to the queue of files and folders monitored by SFSMonitor. Return values: 0 for success, 1 if the URL is already monitored, 2 if maximum number of monitored files and directories is reached, 3 for general error.
    public func addURL(_ url: URL, notifyingAbout notification: SFSMonitorNotification = SFSMonitorNotification.all) throws {
        
        // Dispatch Semaphore for coordinating access to the watched URLs array
        let watchedURLsSemaphore = DispatchSemaphore(value: 0)
        
        // Check if the URL is not empty or inaccessible
        guard
            (try? url.checkResourceIsReachable()) == true
        else { throw SFSMonitorError.urlInaccessible }
        
        // The next 2 tests have to read the watchedURLs array. To make this thread-safe,
        // this must be done from our thread-safety dispatch queue.
        // To be able to get the return values from the queue, we will use an internal
        // function with a completion handler. The Dispatch Semaphore will ensure
        // that we do not move on before these tests are complete.
        
        // Variable that records the return values of the tests
        //        var initialTestsValue : Int = 0
        // Internal function that performs the tests
        func initialTests() throws {
            // Make the reads thread-safe
            defer { watchedURLsSemaphore.signal() }
            try self.SFSThreadSafetyQueue.sync {
                // Check if this URL is not already present
                guard
                    SFSMonitor.watchedURLs.keys.contains(url) == false
                else { throw SFSMonitorError.urlAlreadyMonitored }

                // Check if the number of open file descriptors exceeds the limit
                guard
                    SFSMonitor.watchedURLs.count < SFSMonitor.maxMonitored
                else { throw SFSMonitorError.maximumMonitoredURLsReached }

                // If we got here, there was no error to throw
            }
        }
        
        // Call the internal function to perform the tests
        try initialTests()
        // Wait until we get the results back
        watchedURLsSemaphore.wait()

        // Open the file or directory referenced by URL for monitoring only.
        let fileDescriptor = open(FileManager.default.fileSystemRepresentation(withPath: url.path), O_EVTONLY)
        guard fileDescriptor >= 0 else {
            print ("SFSMonitor error: could not create a file descriptor for URL: \(url)")
            throw SFSMonitorError.couldNotCreateFileDescriptor
        }
        
        // Define a dispatch source monitoring the file or directory for additions, deletions, and renamings.
        if let monitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: notification, queue: SFSMonitorQueue) as? DispatchSource {
            
            // Define the block to call when a file change is detected.
            monitorSource.setEventHandler {
                
                // Call out to the `SFSMonitorDelegate` so that it can react appropriately to the change.
                let event = monitorSource.data as DispatchSource.FileSystemEvent
                self.delegate?.receivedNotification(event, url: url, queue: self)
            }

            // Define a cancel handler to ensure the directory is closed when the source is cancelled.
            monitorSource.setCancelHandler {
                close(fileDescriptor)
                self.SFSThreadSafetyQueue.async(flags: .barrier) {
                    SFSMonitor.watchedURLs.removeValue(forKey: url)
                }
            }
            
            // Start monitoring
            monitorSource.resume()

            // Populate our watched URL array within the thread-safe queue
            self.SFSThreadSafetyQueue.async(flags: .barrier) {
                SFSMonitor.watchedURLs[url] = monitorSource
            }

        } else {
            print ("SFSMonitor error: could not create a Dispatch Source for URL: \(url)")
            throw SFSMonitorError.couldNotCreateDispatchSource
        }
    }

    /// A boolean value that indicates whether the entered URL is already being monitored by SFSMonitor.
    public func isURLWatched(_ url: URL) -> Bool {
        // This query has to be done through an internal function with a completion handler
        // (with the help of a semaphore) so that we can use the dispatch queue for thread protection
        let isURLWatchedSemaphore = DispatchSemaphore(value: 0)
        func isURLWatchedInternalFunction(completion: (Bool) -> ()) {
            self.SFSThreadSafetyQueue.sync {
                completion(SFSMonitor.watchedURLs.keys.contains(url))
                isURLWatchedSemaphore.signal()
            }
        }
        var returnValue = false
        isURLWatchedInternalFunction {completion in
            returnValue = completion
        }
        isURLWatchedSemaphore.wait()
        return returnValue
    }

    /// Remove URL from the SFSMonitor queue and close its file reference.
    public func removeURL(_ url: URL) {
        SFSThreadSafetyQueue.sync {
            if let SFSMonitorSource = SFSMonitor.watchedURLs[url] {
                
                // Cancel dispatch source and remove it from list
                SFSMonitorSource.cancel()
            }
        }
    }

    /// Reset the SFSMonitor queue.
    public func removeAllURLs() {
        SFSThreadSafetyQueue.sync {
            for watchedUrl in SFSMonitor.watchedURLs {
                watchedUrl.value.cancel()
            }
        }
    }

    /// The number of URLs being watched by SFSMonitor.
    public func numberOfWatchedURLs() -> Int {
        // This query has to be done through an internal function with a completion handler
        // (with the help of a semaphore) so that we can use the dispatch queue for thread protection
        let numberOfWatchedURLsSemaphore = DispatchSemaphore(value: 0)
        func numberOfWatchedURLsInternal(completion: (Int) -> ()) {
            self.SFSThreadSafetyQueue.sync {
                completion(SFSMonitor.watchedURLs.count)
                numberOfWatchedURLsSemaphore.signal()
            }
        }
        var returnValue : Int = 0
        numberOfWatchedURLsInternal { completion in
            returnValue = completion
        }
        numberOfWatchedURLsSemaphore.wait()
        return returnValue
    }
    
    /// An array of all URLs being watched by SFSMonitor.
    public func URLsWatched() -> [URL] {
        // This query has to be done through an internal function with a completion handler
        // (with the help of a semaphore) so that we can use the dispatch queue for thread protection
        let URLsWatchedSemaphore = DispatchSemaphore(value: 0)
        func URLsWatchedInternal(completion: ([URL]) -> ()) {
            self.SFSThreadSafetyQueue.sync {
                completion(Array(SFSMonitor.watchedURLs.keys))
                URLsWatchedSemaphore.signal()
            }
        }
        var returnValue : [URL] = []
        URLsWatchedInternal { completion in
            returnValue = completion
        }
        URLsWatchedSemaphore.wait()
        return returnValue
    }
    
    /// Set the maximal number of file descriptors allowed to be opened. On iOS and iPadOS it is recommended to be kept at 224 or under (allowing 32 more for the app).
    public func setMaxMonitored(number: Int) {
        SFSMonitor.maxMonitored = number
    }
    
    /// Get the current maximal number of file descriptors allowed to be opened.
    public func getMaxMonitored() -> Int {
        return SFSMonitor.maxMonitored
    }

    public enum SFSMonitorError: Error {
        case urlAlreadyMonitored
        case urlInaccessible
        case maximumMonitoredURLsReached
        case couldNotCreateFileDescriptor
        case couldNotCreateDispatchSource
    }
}

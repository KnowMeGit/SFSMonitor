import Foundation

public typealias SFSMonitorNotification = DispatchSource.FileSystemEvent

extension SFSMonitorNotification {
	/// A method to convert the SFSMonitor OptionSet to String.
	public func toStrings() -> [SFSMonitorNotificationString] {
		var s = [SFSMonitorNotificationString]()
		if contains(.rename)    { s.append(.rename) }
		if contains(.write)     { s.append(.write) }
		if contains(.delete)    { s.append(.delete) }
        if contains(.attrib)    { s.append(.attributeChange) }
        if contains(.extend)    { s.append(.sizeIncrease) }
		if contains(.link)      { s.append(.linkCountChange) }
		if contains(.revoke)    { s.append(.accessRevocation) }
		if contains(.funlock)   { s.append(.unlock) }
		return s
	}
}

extension SFSMonitorNotification: CustomStringConvertible {
    public var description: String {
        toStrings().map(\.rawValue).joined(separator: ", ") + "\(rawValue)"
    }
}

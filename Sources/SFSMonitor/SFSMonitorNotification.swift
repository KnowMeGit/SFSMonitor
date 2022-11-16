import Foundation

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

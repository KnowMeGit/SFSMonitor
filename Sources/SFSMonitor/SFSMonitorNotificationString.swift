import Foundation

/// A string representation of possible changes detected by SFSMonitor.
public enum SFSMonitorNotificationString: String {
	case rename = "Rename"
	case write = "Write"
	case delete = "Delete"
	case attributeChange = "AttributeChange"
	case sizeIncrease = "SizeIncrease"
	case linkCountChange = "LinkCountChange"
	case accessRevocation = "AccessRevocation"
	case unlock = "Unlock"
	case dataAvailable = "DataAvailable"
}

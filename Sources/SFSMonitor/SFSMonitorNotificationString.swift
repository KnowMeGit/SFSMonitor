import Foundation

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

import Foundation

class SleepPrevention {
    
    static let shared = SleepPrevention()
    
    private var currentActivity: NSObjectProtocol?
    private var isActive = false
    
    private init() {}
    
    func beginActivity(reason: String = "Processing video shorts") {
        guard !isActive else {
            print("Sleep prevention already active")
            return
        }
        
        currentActivity = ProcessInfo.processInfo.beginActivity(
            options: [.idleSystemSleepDisabled, .suddenTerminationDisabled, .automaticTerminationDisabled],
            reason: reason
        )
        
        isActive = true
        print("Sleep prevention activated: \(reason)")
    }
    
    func endActivity() {
        guard isActive, let activity = currentActivity else {
            print("No active sleep prevention to end")
            return
        }
        
        ProcessInfo.processInfo.endActivity(activity)
        currentActivity = nil
        isActive = false
        print("Sleep prevention deactivated")
    }
    
    var isPreventingSleep: Bool {
        return isActive
    }
}

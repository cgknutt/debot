import SwiftUI
import Combine
import Foundation
import QuartzCore

/// A performance monitoring class that tracks FPS and memory usage to dynamically adjust app quality
class FPSMonitor: ObservableObject {
    // Singleton instance
    static let shared = FPSMonitor()
    
    // Constants
    private let targetFPS: Double = 60.0
    private let lowFPSThreshold: Double = 45.0
    private let highFPSThreshold: Double = 58.0
    
    // Quality levels available
    enum QualityLevel: Int, CaseIterable {
        case low = 0
        case medium = 1
        case high = 2
        
        var description: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
    }
    
    // Published properties for UI binding
    @Published var currentQuality: QualityLevel = .high
    @Published var currentFPS: Double = 60.0
    @Published var memoryUsage: Double = 0.0  // In MB
    @Published var isPerformanceModeEnabled = false
    
    // Private properties
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var totalFrameTime: CFTimeInterval = 0
    private var isMonitoring = false
    private var qualityAdjustTimer: Timer?
    private var memoryCheckTimer: Timer?
    private var consecutiveLowFPSCount = 0
    private var consecutiveHighFPSCount = 0
    private var lastQualityAdjustment = Date()
    private var adjustmentCooldown: TimeInterval = 5.0 // Seconds between adjustments
    
    // Notification names
    static let qualityChangedNotification = Notification.Name("FPSMonitorQualityChanged")
    
    private init() {
        // Check user preference for performance mode
        isPerformanceModeEnabled = UserDefaults.standard.bool(forKey: "performanceModeEnabled")
        
        // Retrieve saved quality level if available
        if let savedQuality = UserDefaults.standard.object(forKey: "appQualityLevel") as? Int,
           let qualityLevel = QualityLevel(rawValue: savedQuality) {
            currentQuality = qualityLevel
        }
    }
    
    /// Start monitoring performance
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        lastTimestamp = 0
        frameCount = 0
        totalFrameTime = 0
        
        // Set up display link for FPS monitoring
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        displayLink?.preferredFramesPerSecond = 0 // Use default display refresh rate
        displayLink?.add(to: .main, forMode: .common)
        
        // Set up quality adjustment timer
        qualityAdjustTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.adjustQualityIfNeeded()
        }
        
        // Set up memory check timer
        memoryCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkMemoryUsage()
        }
        
        // Log start
        print("FPS monitoring started")
    }
    
    /// Stop monitoring performance
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        
        // Clean up timers and display link
        displayLink?.invalidate()
        displayLink = nil
        
        qualityAdjustTimer?.invalidate()
        qualityAdjustTimer = nil
        
        memoryCheckTimer?.invalidate()
        memoryCheckTimer = nil
        
        // Log stop
        print("FPS monitoring stopped")
    }
    
    /// Display link callback
    @objc private func displayLinkTick(displayLink: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }
        
        // Calculate time between frames
        let elapsed = displayLink.timestamp - lastTimestamp
        lastTimestamp = displayLink.timestamp
        
        // Track frame times for averaging
        totalFrameTime += elapsed
        frameCount += 1
        
        // Update FPS every 30 frames
        if frameCount >= 30 {
            let averageFrameTime = totalFrameTime / Double(frameCount)
            self.currentFPS = 1.0 / averageFrameTime
            
            // Reset counters
            frameCount = 0
            totalFrameTime = 0
            
            // Debug print FPS
            if isPerformanceModeEnabled {
                print("Current FPS: \(Int(self.currentFPS))")
            }
            
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    /// Check and adjust quality level based on performance
    private func adjustQualityIfNeeded() {
        guard isPerformanceModeEnabled else { return }
        
        // Don't adjust too frequently
        if Date().timeIntervalSince(lastQualityAdjustment) < adjustmentCooldown {
            return
        }
        
        // Handling low FPS
        if currentFPS < lowFPSThreshold {
            consecutiveLowFPSCount += 1
            consecutiveHighFPSCount = 0
            
            if consecutiveLowFPSCount >= 2 && currentQuality != .low {
                lowerQuality()
            }
        }
        // Handling high FPS
        else if currentFPS > highFPSThreshold {
            consecutiveHighFPSCount += 1
            consecutiveLowFPSCount = 0
            
            if consecutiveHighFPSCount >= 5 && currentQuality != .high {
                raiseQuality()
            }
        }
        // Reset counters if in an acceptable range
        else {
            consecutiveLowFPSCount = 0
            consecutiveHighFPSCount = 0
        }
    }
    
    /// Lower the quality level
    private func lowerQuality() {
        guard currentQuality != .low else { return }
        
        let newQuality: QualityLevel
        switch currentQuality {
        case .high:
            newQuality = .medium
        case .medium, .low:
            newQuality = .low
        }
        
        setQuality(newQuality)
    }
    
    /// Raise the quality level
    private func raiseQuality() {
        guard currentQuality != .high else { return }
        
        let newQuality: QualityLevel
        switch currentQuality {
        case .low:
            newQuality = .medium
        case .medium, .high:
            newQuality = .high
        }
        
        setQuality(newQuality)
    }
    
    /// Force a specific quality level
    func forceQualityLevel(_ level: QualityLevel) {
        setQuality(level)
    }
    
    /// Set the quality level and notify observers
    private func setQuality(_ level: QualityLevel) {
        guard level != currentQuality else { return }
        
        DispatchQueue.main.async {
            self.currentQuality = level
            self.lastQualityAdjustment = Date()
            
            // Save to user defaults
            UserDefaults.standard.set(level.rawValue, forKey: "appQualityLevel")
            
            // Post notification of quality change
            NotificationCenter.default.post(
                name: FPSMonitor.qualityChangedNotification,
                object: nil,
                userInfo: ["quality": level]
            )
            
            // Log quality change
            print("Quality adjusted to: \(level.description)")
        }
    }
    
    /// Enable or disable performance mode
    func setPerformanceMode(enabled: Bool) {
        isPerformanceModeEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "performanceModeEnabled")
        
        if enabled && !isMonitoring {
            startMonitoring()
        } else if !enabled && isMonitoring {
            stopMonitoring()
        }
    }
    
    /// Check memory usage of the app
    private func checkMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        
        DispatchQueue.main.async {
            self.memoryUsage = memoryUsage
            
            // If memory usage is too high, consider lowering quality
            if memoryUsage > 500 && self.currentQuality != .low {  // 500MB threshold
                self.lowerQuality()
            }
        }
    }
    
    /// Get current memory usage in MB
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024)
        } else {
            return 0
        }
    }
    
    /// Reset any performance tracking data
    func reset() {
        consecutiveLowFPSCount = 0
        consecutiveHighFPSCount = 0
        frameCount = 0
        totalFrameTime = 0
        lastTimestamp = 0
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let qualityLevelChanged = Notification.Name("com.debot.qualityLevelChanged")
} 
import UIKit
import CoreMotion

public class OrientationTracker: ObservableObject {
    public static let shared = OrientationTracker()
    public static let deviceOrientationChangedNotification = NSNotification.Name("DeviceOrientationChangedNotification")
    public var currentDeviceOrientation: UIDeviceOrientation = .portrait
    @Published var currentOrientation: UIDeviceOrientation = .portrait
    
    public var affineTransform: CGAffineTransform {
        var angleRadians: CGFloat
        switch currentDeviceOrientation {
        case .portrait:
            angleRadians = 0
        case .landscapeLeft:
            angleRadians = -0.5 * .pi
        case .landscapeRight:
            angleRadians = 0.5 * .pi
        case .portraitUpsideDown:
            angleRadians = .pi
        default:
            return .identity
        }
        return CGAffineTransform(rotationAngle: angleRadians)
    }
    
    let motionManager: CMMotionManager
    let queue: OperationQueue
    
    init() {
        self.motionManager = CMMotionManager()
        self.motionManager.accelerometerUpdateInterval = 0.1
        self.queue = OperationQueue()
    }
    
    public func startDeviceOrientationTracking() {
        
        motionManager.startAccelerometerUpdates(to: queue) { accelerometerData, error in
            guard error == nil else { return }
            guard let accelerometerData = accelerometerData else { return }
            
            let newDeviceOrientation = self.deviceOrientation(forAccelerometerData: accelerometerData)
            guard newDeviceOrientation != self.currentDeviceOrientation else { return }
            self.currentDeviceOrientation = newDeviceOrientation
            DispatchQueue.main.async {
                self.currentOrientation = newDeviceOrientation
            }
        
            let name = OrientationTracker.deviceOrientationChangedNotification
            NotificationCenter.default.post(name: name,
                                            object: nil,
                                            userInfo: nil)
            
        }
    }
    
    public func stopDeviceOrientationTracking() {
        motionManager.stopAccelerometerUpdates()
    }
    
    func deviceOrientation(forAccelerometerData accelerometerData: CMAccelerometerData) -> UIDeviceOrientation {
        let treshold = 0.55
        if accelerometerData.acceleration.x >= treshold {
            return .landscapeRight
        } else if accelerometerData.acceleration.x <= -treshold {
            return .landscapeLeft
        } else if accelerometerData.acceleration.y <= -treshold {
            return .portrait
        } else if accelerometerData.acceleration.y >= treshold {
            return .portraitUpsideDown
        } else {
            return currentDeviceOrientation
        }
    }
}

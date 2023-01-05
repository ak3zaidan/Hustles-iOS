import SwiftUI
import UIKit
import AVFoundation
import Photos

public protocol CameraViewControllerDelegate {
    func noCameraDetected()
    func cameraSessionStarted()
    func didCapturePhoto()
    func didRotateCamera()
    func didChangeFlashMode()
    func didFocusOnPoint(_ point: CGPoint)
    func didChangeZoomLevel(_ zoom: CGFloat)
    func didStartVideoRecording()
    func didFinishVideoRecording()
    func didFinishProcessingPhoto(_ image: UIImage)
    func didFinishSavingWithError(_ image: UIImage, error: NSError?, contextInfo: UnsafeRawPointer)
    func didChangeMaximumVideoDuration(_ duration: Double)
}

public class UserEvents: ObservableObject {
    @Published public var didAskToCapturePhoto = false
    @Published public var didAskToRotateCamera = false
    @Published public var didAskToChangeFlashMode = false
    @Published public var didAskToRecordVideo = false
    @Published public var didAskToStopRecording = false
    
    public init() { }
}

public protocol CameraActions {
    func takePhoto(events: UserEvents)
    func toggleVideoRecording(events: UserEvents)
    func rotateCamera(events: UserEvents)
    func changeFlashMode(events: UserEvents)
}

public extension CameraActions {
    func takePhoto(events: UserEvents) {
        events.didAskToCapturePhoto = true
    }
    
    func toggleVideoRecording(events: UserEvents) {
        if events.didAskToRecordVideo {
            events.didAskToStopRecording = true
        } else {
            events.didAskToRecordVideo = true
        }
    }
    
    func rotateCamera(events: UserEvents) {
        events.didAskToRotateCamera = true
    }
    
    func changeFlashMode(events: UserEvents) {
        events.didAskToChangeFlashMode = true
    }
}

public struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var events: UserEvents
    class RandomClass { }
    let x = RandomClass()

    @EnvironmentObject var pop: PopToRoot
    private var applicationName: String
    private var preferredStartingCameraType: AVCaptureDevice.DeviceType
    private var preferredStartingCameraPosition: AVCaptureDevice.Position
    private var focusImage: String?
    private var pinchToZoom: Bool
    private var tapToFocus: Bool
    private var doubleTapCameraSwitch: Bool
    
    public init(events: UserEvents, applicationName: String, preferredStartingCameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera, preferredStartingCameraPosition: AVCaptureDevice.Position = .back, focusImage: String? = nil, pinchToZoom: Bool = true, tapToFocus: Bool = true, doubleTapCameraSwitch: Bool = true) {
        self.events = events
        
        self.applicationName = applicationName
        
        self.focusImage = focusImage
        self.preferredStartingCameraType = preferredStartingCameraType
        self.preferredStartingCameraPosition = preferredStartingCameraPosition
        
        self.pinchToZoom = pinchToZoom
        self.tapToFocus = tapToFocus
        self.doubleTapCameraSwitch = doubleTapCameraSwitch
    }
    
    public func makeUIViewController(context: Context) -> CameraViewController {
        let cameraViewController = CameraViewController()
        cameraViewController.delegate = context.coordinator
        
        cameraViewController.applicationName = applicationName
        cameraViewController.preferredStartingCameraType = preferredStartingCameraType
        cameraViewController.preferredStartingCameraPosition = preferredStartingCameraPosition
        
        cameraViewController.focusImage = focusImage
        
        cameraViewController.pinchToZoom = pinchToZoom
        cameraViewController.tapToFocus = tapToFocus
        cameraViewController.doubleTapCameraSwitch = doubleTapCameraSwitch
        
        return cameraViewController
    }
    
    public func updateUIViewController(_ cameraViewController: CameraViewController, context: Context) {
        if events.didAskToCapturePhoto {
            cameraViewController.takePhoto()
        }
        
        if events.didAskToRotateCamera {
            cameraViewController.rotateCamera()
        }
        
        if events.didAskToChangeFlashMode {
            cameraViewController.changeFlashMode()
        }
        
        if events.didAskToRecordVideo || events.didAskToStopRecording {
            cameraViewController.toggleMovieRecording()
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, CameraViewControllerDelegate {
        var parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        public func cameraSessionStarted() { }
        public func noCameraDetected() { }

        public func didRotateCamera() {
            parent.events.didAskToRotateCamera = false
        }
        
        public func didCapturePhoto() {
            parent.events.didAskToCapturePhoto = false
        }
        
        public func didChangeFlashMode() {
            parent.events.didAskToChangeFlashMode = false
        }
        
        public func didFinishProcessingPhoto(_ image: UIImage) {
            parent.pop.snapImage = image
        }
        
        public func didFinishSavingWithError(_ image: UIImage, error: NSError?, contextInfo: UnsafeRawPointer) { }
        
        public func didChangeZoomLevel(_ zoom: CGFloat) { }
        
        public func didFocusOnPoint(_ point: CGPoint) {
            parent.pop.focusLocation = (point.x, point.y)
        }
        
        public func didStartVideoRecording() { }
        
        public func didFinishVideoRecording() {
            parent.events.didAskToRecordVideo = false
            parent.events.didAskToStopRecording = false
        }
        
        public func didSavePhoto() { }
        
        public func didChangeMaximumVideoDuration(_ duration: Double) { }
    }
}

public class PreviewView: UIView {
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer`")
        }
        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    override public class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}

public class CameraViewController: UIViewController {
    public var applicationName: String?
    public var preferredStartingCameraType: AVCaptureDevice.DeviceType?
    public var preferredStartingCameraPosition: AVCaptureDevice.Position?
    public var delegate: CameraViewControllerDelegate?
    public var maximumVideoDuration: Double = 10.0
    public var videoQuality: AVCaptureSession.Preset = .high
    public var flashMode: AVCaptureDevice.FlashMode = .off
    public var pinchToZoom = true
    public var maxZoomScale = CGFloat.greatestFiniteMagnitude
    public var tapToFocus = true
    public var focusImage: String?
    public var doubleTapCameraSwitch = true
    public var swipeToZoom = true
    public var swipeToZoomInverted = false
    public var allowBackgroundAudio = true
    public var videoGravity: AVLayerVideoGravity = .resizeAspect
    public var audioEnabled = true
    private(set) public var isVideoRecording = false
    private(set) public var isSessionRunning = false
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var zoomScale: CGFloat = 1
    private var beginZoomScale: CGFloat = 1
    private var setupResult: SessionSetupResult = .success
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    private var previewView = PreviewView()
    private var videoDeviceInput: AVCaptureDeviceInput!
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoDevice: AVCaptureDevice?
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    private var sessionRunning = false
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera], mediaType: .video, position: .unspecified)
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        previewView.session = session
        previewView.videoPreviewLayer.videoGravity = videoGravity
        previewView.videoPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        previewView.frame = view.frame
        view.addSubview(previewView)

        addGestureRecognizers()

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
            
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            setupResult = .notAuthorized
        }

        sessionQueue.async {
            self.configureSession()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "\(self.applicationName!) doesn't have permission to use the camera, please change privacy settings"
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                    
                    let alertController = UIAlertController(title: self.applicationName!, message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                            style: .`default`,
                                                            handler: { _ in
                                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                          options: [:],
                                                                                          completionHandler: nil)
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            case .configurationFailed:
                DispatchQueue.main.async {
                    let alertMsg = "Alert message when something goes wrong during capture session configuration"
                    let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
                    let alertController = UIAlertController(title: self.applicationName!, message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            }
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }

    private func configureSession() {
        if setupResult != .success {
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .high

        do {
            var defaultVideoDevice: AVCaptureDevice?
            if let preferredCameraDevice = AVCaptureDevice.default(preferredStartingCameraType!, for: .video, position: preferredStartingCameraPosition!) {
                defaultVideoDevice = preferredCameraDevice
            } else if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                defaultVideoDevice = frontCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async { }
            } else {
                print("Couldn't add video device input to the session.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }

        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
            }
        } catch {
            print("Could not create audio device input: \(error)")
        }

        let photoOutput = AVCapturePhotoOutput()
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            self.photoOutput = photoOutput
        } else {
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }

        let movieFileOutput = AVCaptureMovieFileOutput()
        
        if self.session.canAddOutput(movieFileOutput) {
            self.session.addOutput(movieFileOutput)
            
            if let connection = movieFileOutput.connection(with: AVMediaType.video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            
            self.movieFileOutput = movieFileOutput
        }

        session.commitConfiguration()
    }
    
    private func savePhoto(_ image: UIImage) { }
    
    @objc private func didFinishSavingWithError(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async {
            self.delegate?.didFinishSavingWithError(image, error: error, contextInfo: contextInfo)
        }
    }
    
    private func savePhoto(_ photoData: Data) { }

    public func takePhoto() {
        sessionQueue.async {
            let photoSettings = AVCapturePhotoSettings()
            
            if self.videoDeviceInput!.device.isFlashAvailable {
                photoSettings.flashMode = self.flashMode
            }
            
            self.photoOutput?.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    public func rotateCamera() {
        sessionQueue.async {
            let currentVideoDevice = self.videoDeviceInput?.device
            let currentPosition = currentVideoDevice?.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType

            switch currentPosition {
            case .unspecified, .none, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInTrueDepthCamera
                
            @unknown default:
                print("Unknown capture position. Defaulting to back, dual-camera.")
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
            }
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil

            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let captureDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.session.beginConfiguration()

                    self.session.removeInput(self.videoDeviceInput!)
                    if self.session.canAddInput(captureDeviceInput) {
                        self.session.addInput(captureDeviceInput)
                        self.videoDeviceInput = captureDeviceInput
                    } else {
                        self.session.addInput(self.videoDeviceInput!)
                    }
                    
                    if let connection = self.movieFileOutput?.connection(with: .video) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    self.session.commitConfiguration()
                } catch {
                    print("Error occurred while creating video device input: \(error)")
                }
                
            }
            DispatchQueue.main.async {
                self.delegate?.didRotateCamera()
            }
        }
    }
    
    public func changeFlashMode() {
        switch flashMode {
        case .off:
            flashMode = .auto
        case .auto:
            flashMode = .on
        default:
            flashMode = .off
        }
        
        DispatchQueue.main.async {
            self.delegate?.didChangeFlashMode()
        }
    }
    
    public func toggleMovieRecording() {
        guard let movieFileOutput = self.movieFileOutput else {
            return
        }

        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        
        sessionQueue.async {
            if !movieFileOutput.isRecording {
                if UIDevice.current.isMultitaskingSupported {
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }
 
                let movieFileOutputConnection = movieFileOutput.connection(with: .video)
                movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!
                
                let availableVideoCodecTypes = movieFileOutput.availableVideoCodecTypes
                
                if availableVideoCodecTypes.contains(.hevc) {
                    movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: movieFileOutputConnection!)
                }
 
                let outputFileName = NSUUID().uuidString
                let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
            } else {
                movieFileOutput.stopRecording()
            }
        }
    }
    
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        DispatchQueue.main.async {
            self.view.layer.opacity = 0
            UIView.animate(withDuration: 0.5) {
                self.view.layer.opacity = 1
            }
            self.delegate?.didCapturePhoto()
        }
    }

    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else { print("Error capturing photo: \(error!)"); return }
        
        if let photoData = photo.fileDataRepresentation() {
            let dataProvider = CGDataProvider(data: photoData as CFData)
            let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!,
                                     decode: nil,
                                     shouldInterpolate: true,
                                     intent: CGColorRenderingIntent.defaultIntent)
            
            let image = UIImage(cgImage: cgImageRef!, scale: 1, orientation: .right)

            savePhoto(image)

            DispatchQueue.main.async {
                self.delegate?.didFinishProcessingPhoto(image)
            }
        }
    }
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        DispatchQueue.main.async {
            self.delegate?.didStartVideoRecording()
        }
    }

    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        func cleanup() {
            let path = outputFileURL.path
            if FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch {
                    print("Could not remove file at url: \(outputFileURL)")
                }
            }
            
            if let currentBackgroundRecordingID = backgroundRecordingID {
                backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
                
                if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                }
            }
        }
        
        DispatchQueue.main.async {
            self.delegate?.didFinishVideoRecording()
        }
        
        var success = true
        
        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
        }
        
        if success {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges({
                        let options = PHAssetResourceCreationOptions()
                        options.shouldMoveFile = true
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .video, fileURL: outputFileURL, options: options)
                    }, completionHandler: { success, error in
                        if !success {
                            print("\(self.applicationName!) couldn't save the movie to your photo library: \(String(describing: error))")
                        }
                        cleanup()
                    }
                    )
                } else {
                    cleanup()
                }
            }
        } else {
            cleanup()
        }
    }
}

extension CameraViewController {
    @objc func singleTapGesture(tap: UITapGestureRecognizer) {
        guard tapToFocus == true else {
            return
        }
        
        let screenSize = previewView.bounds.size
        let tapPoint = tap.location(in: previewView)
        let x = tapPoint.y / screenSize.height
        let y = 1.0 - tapPoint.x / screenSize.width
        let focusPoint = CGPoint(x: x, y: y)
        
        let device = videoDeviceInput!.device
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported == true {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
            }
            device.exposurePointOfInterest = focusPoint
            device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            device.unlockForConfiguration()
            
            DispatchQueue.main.async {
                self.delegate?.didFocusOnPoint(tapPoint)
                self.focusAnimationAt(tapPoint)
            }
        }
        catch { }
    }

    @objc fileprivate func doubleTapGesture(tap: UITapGestureRecognizer) {
        guard doubleTapCameraSwitch == true else {
            return
        }
        rotateCamera()
    }

    @objc fileprivate func zoomGesture(pinch: UIPinchGestureRecognizer) {
        guard pinchToZoom == true else {
            return
        }
        do {
            let captureDevice = videoDeviceInput?.device
            try captureDevice?.lockForConfiguration()
            
            zoomScale = min(maxZoomScale, max(1.0, min(beginZoomScale * pinch.scale,  captureDevice!.activeFormat.videoMaxZoomFactor)))
            
            captureDevice?.videoZoomFactor = zoomScale
            
            DispatchQueue.main.async {
                self.delegate?.didChangeZoomLevel(self.zoomScale)
            }
            
            captureDevice?.unlockForConfiguration()
            
        } catch {
            print("E")
        }
    }
    
    fileprivate func addGestureRecognizers() {
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapGesture(tap:)))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.delegate = self
        previewView.addGestureRecognizer(singleTapGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapGesture(tap:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delegate = self
        previewView.addGestureRecognizer(doubleTapGesture)
        
        singleTapGesture.require(toFail: doubleTapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(zoomGesture(pinch:)))
        pinchGesture.delegate = self
        previewView.addGestureRecognizer(pinchGesture)
    }
}

extension CameraViewController : UIGestureRecognizerDelegate {

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UIPinchGestureRecognizer.self) {
            beginZoomScale = zoomScale;
        }
        return true
    }
}

extension CameraViewController {
    private func focusAnimationAt(_ point: CGPoint) {
        guard let focusImage = self.focusImage else {
            return
        }
        let image = UIImage(named: focusImage)
        let focusView = UIImageView(image: image)
        focusView.center = point
        focusView.alpha = 0.0
        self.view.addSubview(focusView)
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }) { (success) in
            UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseInOut, animations: {
                focusView.alpha = 0.0
                focusView.transform = CGAffineTransform(translationX: 0.6, y: 0.6)
            }) { (success) in
                focusView.removeFromSuperview()
            }
        }
    }
}

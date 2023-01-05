import SwiftUI
import AVKit
import AVFoundation

struct FocusLocation {
    let x: CGFloat
    let y: CGFloat
    let id = UUID()
}

struct CameraStoryView: View {
    @EnvironmentObject var cameraModel: CameraViewModel
    var body: some View {
        
        GeometryReader { proxy in
            let size = proxy.size
            
            CameraPreview(size: size).environmentObject(cameraModel)
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.black.opacity(0.25))
                
                Rectangle()
                    .fill(.orange)
                    .frame(width: size.width * (cameraModel.recordedDuration / cameraModel.maxDuration))
            }
            .frame(height: 8)
            .frame(maxHeight: .infinity,alignment: .top)
        }
        .alert(isPresented: $cameraModel.alert) {
            Alert(title: Text("Please Enable Camera and Microphone Access!"))
        }
        .onReceive(Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()) { _ in
            if cameraModel.recordedDuration <= cameraModel.maxDuration && cameraModel.isRecording{
                cameraModel.recordedDuration += 0.01
            }
            
            if cameraModel.recordedDuration >= cameraModel.maxDuration && cameraModel.isRecording{
                cameraModel.stopRecording(shouldToggle: true)
                cameraModel.isRecording = false
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    @EnvironmentObject var cameraModel : CameraViewModel
    var size: CGSize
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(origin: .zero, size: size))
        guard let preview = cameraModel.preview else { return view }

        preview.frame = view.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        DispatchQueue.global(qos: .userInitiated).async {
            if !self.cameraModel.session.isRunning {
                self.cameraModel.session.startRunning()
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) { }
}


class CameraViewModel: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCaptureMovieFileOutput()
    @Published var preview: AVCaptureVideoPreviewLayer!
    @Published var isRecording: Bool = false
    @Published var recordedURLs: [URL] = []
    @Published var previewURL: URL?
    @Published var showPreview: Bool = false
    @Published var recordedDuration: CGFloat = 0
    @Published var maxDuration: CGFloat = 25
    @Published var capturedImage: UIImage?
    @Published var photoOutput = AVCapturePhotoOutput()
    @Published var flashMode: AVCaptureDevice.TorchMode = .off
    var currentCameraPosition: AVCaptureDevice.Position = .back
    @Published var photoMode: Bool = true
    @Published var isVideoFlashOn: Bool = false
    
    override init() {
        super.init()
        self.checkPermission()
        self.preview = AVCaptureVideoPreviewLayer(session: session)
        self.preview.videoGravity = .resizeAspectFill
    }
    
    func focus(at point: CGPoint) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        do {
            try device.lockForConfiguration()

            let focusPoint = preview.captureDevicePointConverted(fromLayerPoint: point)

            if device.isFocusModeSupported(.autoFocus) && device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
            }

            if device.isExposureModeSupported(.autoExpose) && device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .autoExpose
            }

            device.unlockForConfiguration()
        } catch {
            print("Error focusing camera: \(error.localizedDescription)")
        }
    }
    
    func flashSelect(on: Bool){
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        do {
            try device.lockForConfiguration()

            if device.isTorchAvailable {
                let newTorchMode: AVCaptureDevice.TorchMode = on ? .on : .off
                self.flashMode = newTorchMode
                device.torchMode = newTorchMode

                if device.isFocusModeSupported(.autoFocus) {
                    device.focusMode = .autoFocus
                }
                device.unlockForConfiguration()
            } else {
                device.unlockForConfiguration()
                print("NA")
            }
        } catch {
            print("E")
        }
    }
    
    func zoom(_ delta: CGFloat) {
        guard let device = (currentCameraPosition == .back ? AVCaptureDevice.default(for: .video) : AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)) else { return }
        do {
            try device.lockForConfiguration()
            
            var newZoomFactor = device.videoZoomFactor * delta
            newZoomFactor = max(1.0, min(newZoomFactor, device.activeFormat.videoMaxZoomFactor))
            
            device.videoZoomFactor = newZoomFactor
            device.unlockForConfiguration()
        } catch {
            print("E")
        }
    }
    
    func switchCamera() {
        if isRecording {
            stopRecording(shouldToggle: false)
        } else {
            self.flipCamera()
        }
    }
    
    func addAudio(){
        do {
            self.session.beginConfiguration()
        
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            if self.session.canAddInput(audioInput){
                self.session.addInput(audioInput)
            }

            self.session.commitConfiguration()
        }
        catch {
            print("E")
        }
    }
    
    func removeAudio(){
        session.beginConfiguration()
        
        session.inputs.forEach { input in
            if let deviceInput = input as? AVCaptureDeviceInput {
                let device = deviceInput.device
                
                if device.hasMediaType(.audio) {
                    session.removeInput(input)
                }
            }
        }
        
        session.commitConfiguration()
    }
    
    func flipCamera() {
        guard let currentVideoInput = session.inputs.first as? AVCaptureDeviceInput else {
            print("E")
            return
        }

        currentCameraPosition = (currentCameraPosition == .back) ? .front : .back

        session.beginConfiguration()
        
        session.inputs.forEach { input in
            if let deviceInput = input as? AVCaptureDeviceInput {
                let device = deviceInput.device
                
                if !device.hasMediaType(.audio) {
                    session.removeInput(input)
                }
            }
        }

        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition) else {
            print("E")
            session.commitConfiguration()
            return
        }

        do {
            let newVideoInput = try AVCaptureDeviceInput(device: newCamera)
            if session.canAddInput(newVideoInput) {
                session.addInput(newVideoInput)
            } else {
                currentCameraPosition = (currentCameraPosition == .back) ? .front : .back
                session.addInput(currentVideoInput)
            }
        } catch {
            currentCameraPosition = (currentCameraPosition == .back) ? .front : .back
            session.addInput(currentVideoInput)
        }

        session.commitConfiguration()
    }
    
    func takePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            return
        }
        
        if let data = photo.fileDataRepresentation() {
            let image = UIImage(data: data)!
            
            if currentCameraPosition == .back {
                self.capturedImage = image
            } else {
                let ciImage = CIImage(cgImage: image.cgImage!).oriented(forExifOrientation: 6)
                let flippedImage = ciImage.transformed(by: CGAffineTransform(scaleX: -1, y: 1))
                self.capturedImage = UIImage.convert(from: flippedImage)
            }
        }
    }

    func checkPermission(){
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            checkAudioPermission()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                if status {
                    self.checkAudioPermission()
                }
            }
        case .denied:
            self.alert.toggle()
            return
        default:
            return
        }
    }
    
    func checkAudioPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            setUp()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { (audioStatus) in
                if audioStatus {
                    self.setUp()
                }
            }
        case .denied:
            self.alert.toggle()
            return
        default:
            return
        }
    }
    
    func setUp(){
        do {
            self.session.beginConfiguration()
            let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            let videoInput = try AVCaptureDeviceInput(device: cameraDevice!)
            
            if self.session.canAddInput(videoInput){
                self.session.addInput(videoInput)
            }

            if self.session.canAddOutput(self.output){
                self.session.addOutput(self.output)
            }
            
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            
            try cameraDevice?.lockForConfiguration()
            if cameraDevice?.activeFormat.videoMaxZoomFactor ?? 1 > 1 {
                cameraDevice?.videoZoomFactor = 1
            }
            cameraDevice?.unlockForConfiguration()
            
            self.session.commitConfiguration()
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func startRecording(){
        let tempURL = NSTemporaryDirectory() + "\(Date()).mov"
        output.startRecording(to: URL(fileURLWithPath: tempURL), recordingDelegate: self)
        isRecording = true
    }
    
    func stopRecording(shouldToggle: Bool){
        output.stopRecording()
        
        if shouldToggle {
            isRecording = false
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if isRecording {
            flipCamera()

            startRecording()
            
            if !photoMode && isRecording && currentCameraPosition == .back && isVideoFlashOn {
                flashSelect(on: true)
            }
        }
        if error != nil {
            return
        }
        
        self.recordedURLs.append(outputFileURL)
        if self.recordedURLs.count == 1{
            self.previewURL = outputFileURL
            return
        }
        
        // CONVERTING URLs TO ASSETS
        let assets = recordedURLs.compactMap { url -> AVURLAsset in
            return AVURLAsset(url: url)
        }
        
        self.previewURL = nil
        // MERGING VIDEOS
        Task {
            await mergeVideos(assets: assets) { exporter in
                exporter.exportAsynchronously {
                    if exporter.status == .failed {
                        print(exporter.error!)
                    }
                    else{
                        if let finalURL = exporter.outputURL{
                            print(finalURL)
                            DispatchQueue.main.async {
                                self.previewURL = finalURL
                            }
                        }
                    }
                }
            }
        }
    }
    
    func mergeVideos(assets: [AVURLAsset], completion: @escaping (_ exporter: AVAssetExportSession)->()) async {
        
        let compostion = AVMutableComposition()
        var lastTime: CMTime = .zero
        
        guard let videoTrack = compostion.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else{return}
        guard let audioTrack = compostion.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else{return}
        
        for asset in assets {
            // Linking Audio and Video
            do {
                try await videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.load(.duration)), of: asset.loadTracks(withMediaType: .video)[0], at: lastTime)
                // Safe Check if Video has Audio
                if try await !asset.loadTracks(withMediaType: .audio).isEmpty {
                    try await audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.load(.duration)), of: asset.loadTracks(withMediaType: .audio)[0], at: lastTime)
                }
            } catch {
                print(error.localizedDescription)
            }
            
            do {
                lastTime = try await CMTimeAdd(lastTime, asset.load(.duration))
            } catch {
                print(error.localizedDescription)
            }
        }
        
        // MARK: Temp Output URL
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory() + "Reel-\(Date()).mp4")
        
        // VIDEO IS ROTATED
        // BRINGING BACK TO ORIGNINAL TRANSFORM
        
        let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        
        // MARK: Transform
        var transform = CGAffineTransform.identity
        transform = transform.rotated(by: 90 * (.pi / 180))
        transform = transform.translatedBy(x: 0, y: -videoTrack.naturalSize.height)
        layerInstructions.setTransform(transform, at: .zero)
        
        let instructions = AVMutableVideoCompositionInstruction()
        instructions.timeRange = CMTimeRange(start: .zero, duration: lastTime)
        instructions.layerInstructions = [layerInstructions]
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
        videoComposition.instructions = [instructions]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        guard let exporter = AVAssetExportSession(asset: compostion, presetName: AVAssetExportPresetHighestQuality) else{return}
        exporter.outputFileType = .mp4
        exporter.outputURL = tempURL
        exporter.videoComposition = videoComposition
        completion(exporter)
    }
}

extension UIImage {
    static func convert(from ciImage: CIImage) -> UIImage {
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)!
        let image = UIImage(cgImage: cgImage)
        return image
    }
}

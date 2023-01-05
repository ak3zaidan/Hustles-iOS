import SwiftUI
import AVFoundation

public final class AudioRecorder: NSObject, ObservableObject {
    @Published public var recordings: [Recording] = []
    @Published var recording = false
    @Published var soundSamples: [RecordingSampleModel]
    private var currentSample: RecordingSampleModel = .init(sample: .zero)
    private let numberOfSamples: Int
    private var timer: Timer?
    var audioRecorder = AVAudioRecorder()
    let audioFormatID: AudioFormatID
    let sampleRateKey: Float
    let noOfchannels: Int
    let audioQuality: AVAudioQuality
    
    public init(numberOfSamples: Int, audioFormatID: AudioFormatID, audioQuality: AVAudioQuality, noOfChannels: Int = 2, sampleRateKey: Float = 44100.0) {
        self.soundSamples = [RecordingSampleModel](repeating: .init(sample: .zero), count: numberOfSamples)
        self.numberOfSamples = numberOfSamples
        self.audioFormatID = audioFormatID
        self.audioQuality = audioQuality
        self.noOfchannels = noOfChannels
        self.sampleRateKey = sampleRateKey
    }
    
    func startRecording() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
            
        } catch let error {
            print("Failed to set up recording session \(error.localizedDescription)")
        }
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentPath.appendingPathComponent("\(UUID().uuidString).m4a")
        UserDefaults.standard.set(audioFilename.absoluteString, forKey: "tempUrl")
                
        let settings: [String:Any] = [
            AVFormatIDKey: kAudioFormatAppleLossless,
            AVSampleRateKey:44100.0,
            AVNumberOfChannelsKey:2,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.record()
            recording = true
            startMonitoring()
        } catch {
            print("Could not start recording")
        }
    }
    
    func stopRecording() {
        audioRecorder.stop()
        recording = false
        stopMonitoring()
    }
    
    func mergeAudios() async {
        if self.recordings.count > 1 {
            let composition = AVMutableComposition()
            var lastTime: CMTime = .zero
            
            guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
            
            for recording in self.recordings {
                let asset = AVURLAsset(url: recording.fileURL)
                
                do {
                    try await audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.load(.duration)), of: asset.loadTracks(withMediaType: .audio)[0], at: lastTime)
                } catch {
                    print("Error inserting time range: \(error.localizedDescription)")
                }
                
                do {
                    lastTime = try await CMTimeAdd(lastTime, asset.load(.duration))
                } catch {
                    print("Error adding time: \(error.localizedDescription)")
                }
            }
        
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory() + "MergedAudio-\(UUID().uuidString).m4a")
            
            do {
                let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
                exporter?.outputFileType = AVFileType.m4a
                exporter?.outputURL = tempURL
                
                await exporter?.export()
                
                DispatchQueue.main.async {
                    self.recordings = [Recording(fileURL: tempURL)]
                    UserDefaults.standard.set(tempURL.absoluteString, forKey: "tempUrl")
                }
            }
        }
    }
    
    public func deleteRecording(url: URL, onSuccess: (() -> Void)?) {
        do {
            try FileManager.default.removeItem(at: url)
            onSuccess?()
        } catch {
            print("File could not be deleted!")
        }
    }
    
    private func startMonitoring() {
        audioRecorder.isMeteringEnabled = true

        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { [weak self] _ in
            
            guard let this = self else { return }
            
            this.audioRecorder.updateMeters()
            this.soundSamples[this.currentSample.sample] = RecordingSampleModel(sample: Int(this.audioRecorder.averagePower(forChannel: 0)))
            this.currentSample.sample = (this.currentSample.sample + 1) % this.numberOfSamples
        })
    }
    
    func stopMonitoring() {
        audioRecorder.isMeteringEnabled = false
        timer?.invalidate()
    }
    
    public func fetchRecordings() {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryContents = try? fileManager.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil)
        
        if let directoryContents {
            
            for audio in directoryContents {
                let recording = Recording(fileURL: audio)
                recordings.append(recording)
            }
        }
    }
}

public final class AudioRecorderG: NSObject, ObservableObject {
    @Published public var recordings: [Recording] = []
    @Published var recording = false
    @Published var soundSamples: [RecordingSampleModel]
    private var currentSample: RecordingSampleModel = .init(sample: .zero)
    private let numberOfSamples: Int
    private var timer: Timer?
    var audioRecorder = AVAudioRecorder()
    let audioFormatID: AudioFormatID
    let sampleRateKey: Float
    let noOfchannels: Int
    let audioQuality: AVAudioQuality
    
    public init(numberOfSamples: Int, audioFormatID: AudioFormatID, audioQuality: AVAudioQuality, noOfChannels: Int = 2, sampleRateKey: Float = 44100.0) {
        self.soundSamples = [RecordingSampleModel](repeating: .init(sample: .zero), count: numberOfSamples)
        self.numberOfSamples = numberOfSamples
        self.audioFormatID = audioFormatID
        self.audioQuality = audioQuality
        self.noOfchannels = noOfChannels
        self.sampleRateKey = sampleRateKey
    }
    
    func startRecording() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
            
        } catch let error {
            print("Failed to set up recording session \(error.localizedDescription)")
        }
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentPath.appendingPathComponent("\(UUID().uuidString).m4a")
        UserDefaults.standard.set(audioFilename.absoluteString, forKey: "tempUrl")
                
        let settings: [String:Any] = [
            AVFormatIDKey: kAudioFormatAppleLossless,
            AVSampleRateKey:44100.0,
            AVNumberOfChannelsKey:2,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.record()
            recording = true
            startMonitoring()
        } catch {
            print("Could not start recording")
        }
    }
    
    func stopRecording() {
        audioRecorder.stop()
        recording = false
        stopMonitoring()
    }
    
    func mergeAudios() async {
        if self.recordings.count > 1 {
            let composition = AVMutableComposition()
            var lastTime: CMTime = .zero
            
            guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
            
            for recording in self.recordings {
                let asset = AVURLAsset(url: recording.fileURL)
                
                do {
                    try await audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.load(.duration)), of: asset.loadTracks(withMediaType: .audio)[0], at: lastTime)
                } catch {
                    print("Error inserting time range: \(error.localizedDescription)")
                }
                
                do {
                    lastTime = try await CMTimeAdd(lastTime, asset.load(.duration))
                } catch {
                    print("Error adding time: \(error.localizedDescription)")
                }
            }
        
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory() + "MergedAudio-\(UUID().uuidString).m4a")
            
            do {
                let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
                exporter?.outputFileType = AVFileType.m4a
                exporter?.outputURL = tempURL
                
                await exporter?.export()
                
                DispatchQueue.main.async {
                    self.recordings = [Recording(fileURL: tempURL)]
                    UserDefaults.standard.set(tempURL.absoluteString, forKey: "tempUrl")
                }
            }
        }
    }
    
    public func deleteRecording(url: URL, onSuccess: (() -> Void)?) {
        do {
            try FileManager.default.removeItem(at: url)
            onSuccess?()
        } catch {
            print("File could not be deleted!")
        }
    }
    
    private func startMonitoring() {
        audioRecorder.isMeteringEnabled = true

        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { [weak self] _ in
            
            guard let this = self else { return }
            
            this.audioRecorder.updateMeters()
            this.soundSamples[this.currentSample.sample] = RecordingSampleModel(sample: Int(this.audioRecorder.averagePower(forChannel: 0)))
            this.currentSample.sample = (this.currentSample.sample + 1) % this.numberOfSamples
        })
    }
    
    func stopMonitoring() {
        audioRecorder.isMeteringEnabled = false
        timer?.invalidate()
    }
    
    public func fetchRecordings() {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryContents = try? fileManager.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil)
        
        if let directoryContents {
            
            for audio in directoryContents {
                let recording = Recording(fileURL: audio)
                recordings.append(recording)
            }
        }
    }
}

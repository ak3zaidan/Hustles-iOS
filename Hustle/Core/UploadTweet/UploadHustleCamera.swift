import SwiftUI
import Photos
import AVKit
import AVFoundation
import Firebase

struct UploadTweetCamera: View {
    @Binding var uploadCont: [uploadContent]
    @Binding var isImagePickerPresented: Bool
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var globe: GlobeViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @StateObject var cameraModel = UploadCameraViewModel()
    @GestureState private var scale: CGFloat = 1.0
    @State private var previousScale: CGFloat = 1.0
    @State var focusLocation: FocusLocation?
    @State var closeAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @State var showPhotoFlash: Bool = false
    @State var isPhotoFlashOn: Bool = false
    @State var takingPhoto: Bool = false
    @State var askSwitch: Bool = false
    @State private var showPreviewSec = false
    @State var savedPhoto = false
    @State var muted = false
    @State private var currentTime: Double = 0.0
    @State private var totalLength: Double = 1.0
    @State private var savedMemory = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            UploadCameraStoryView()
                .environmentObject(cameraModel)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .padding(.top,10)
                .padding(.bottom,30)
                .onTapGesture(count: 2) {
                    cameraModel.switchCamera()
                }
                .onTapGesture(count: 1) { tapP in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    focusLocation = FocusLocation(x: tapP.x, y: tapP.y)
                    cameraModel.focus(at: CGPoint(x: tapP.x, y: tapP.y))
                }
                .gesture(MagnificationGesture()
                    .updating($scale, body: { (value, state, _) in
                        state = value
                    })
                    .onChanged { value in
                        let delta = value / previousScale
                        cameraModel.zoom(delta)
                        previousScale = value
                    }
                    .onEnded { _ in
                        previousScale = 1.0
                    }
                )
            let w = widthOrHeight(width: true)
            let h = widthOrHeight(width: false)
            if let points = focusLocation, (points.x > 20) && (points.x < w - 20) && (points.y > 80) && (points.y < h - (h * 0.3)) {
                FocusView()
                    .position(x: points.x, y: points.y)
                    .task {
                        do {
                            try await Task.sleep(for: .milliseconds(750))
                            self.focusLocation = nil
                        } catch { }
                    }
                    .id(points.id)
            }
            
            HStack {
                VStack {
                    Button {
                        if cameraModel.previewURL == nil && cameraModel.capturedImage == nil {
                            cameraModel.removeAudio()
                            isImagePickerPresented = false
                        } else {
                            closeAlert.toggle()
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        ZStack {
                            Circle().frame(width: 47, height: 47).foregroundStyle(Color.black.opacity(0.7))
                            Image(systemName: "xmark").foregroundColor(.white)
                        }
                    }
                    Spacer()
                }
                Spacer()
                VStack {
                    Button {
                        cameraModel.switchCamera()
                    } label: {
                        ZStack {
                            Circle().frame(width: 47, height: 47).foregroundStyle(Color.black.opacity(0.7))
                            Image(systemName: "arrow.triangle.2.circlepath.camera").foregroundColor(.white)
                        }
                    }
                    Button {
                        if cameraModel.photoMode {
                            isPhotoFlashOn.toggle()
                        } else {
                            cameraModel.isVideoFlashOn.toggle()
                            
                            if cameraModel.isVideoFlashOn && cameraModel.isRecording && cameraModel.currentCameraPosition == .back {
                                cameraModel.flashSelect(on: true)
                            } else if !cameraModel.isVideoFlashOn {
                                cameraModel.flashSelect(on: false)
                            }
                        }
                    } label: {
                        ZStack {
                            Circle().frame(width: 47, height: 47).foregroundStyle(Color.black.opacity(0.7))
                            Image(systemName: (cameraModel.photoMode && isPhotoFlashOn) || (!cameraModel.photoMode && cameraModel.isVideoFlashOn) ? "bolt.fill" : "bolt")
                                .foregroundColor((cameraModel.photoMode && isPhotoFlashOn) || (!cameraModel.photoMode && cameraModel.isVideoFlashOn) ? .yellow : .white)
                        }
                    }.padding(.top, 10)
                    Spacer()
                }
            }.padding(.horizontal).padding(.top, 35).font(.system(size: 23))
            
            Button {
                if cameraModel.photoMode {
                    takingPhoto = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                        takingPhoto = false
                    }
                    if isPhotoFlashOn {
                        if cameraModel.currentCameraPosition == .back {
                            cameraModel.flashSelect(on: true)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                                cameraModel.flashSelect(on: false)
                            }
                        } else {
                            showPhotoFlash = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                                showPhotoFlash = false
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            cameraModel.takePhoto()
                        }
                    } else {
                        cameraModel.takePhoto()
                    }
                } else {
                    if cameraModel.isRecording {
                        cameraModel.stopRecording(shouldToggle: true)
                        cameraModel.flashSelect(on: false)
                    } else {
                        if cameraModel.currentCameraPosition == .back && cameraModel.isVideoFlashOn {
                            cameraModel.flashSelect(on: true)
                        }
                        cameraModel.startRecording()
                    }
                }
            } label: {
                if cameraModel.isRecording {
                    RoundedRectangle(cornerRadius: 8)
                        .frame(width: 65, height: 65).foregroundStyle(.red).opacity(0.7)
                        .padding(.bottom, 15)
                } else {
                    ZStack {
                        Color.gray.opacity(0.001)
                        Circle().stroke(.white, lineWidth: 7).frame(width: 80, height: 80)
                    }.frame(width: 95, height: 95)
                }
            }.padding(.bottom, 70).disabled(takingPhoto)
            
            HStack {
                if !cameraModel.isRecording {
                    modePicker()
                }
                Spacer()
                if !cameraModel.photoMode && !cameraModel.isRecording && !cameraModel.recordedURLs.isEmpty {
                    Button {
                        if let _ = cameraModel.previewURL {
                            cameraModel.removeAudio()
                            cameraModel.showPreview.toggle()
                        }
                    } label: {
                        if cameraModel.previewURL == nil {
                            ZStack {
                                Circle().frame(width: 47, height: 47).foregroundStyle(Color(UIColor.lightGray))
                                ProgressView().tint(.black)
                            }.padding(.trailing, 20)
                        } else {
                            HStack {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .padding(10)
                            .foregroundColor(.white).font(.body)
                            .background {
                                Capsule().foregroundStyle(.ultraThinMaterial)
                            }
                        }
                    }
                }
            }.padding(.bottom, 95).padding(.horizontal)
        }
        .overlay(content: {
            if cameraModel.previewURL != nil && cameraModel.showPreview {
                videoPreview().transition(.move(edge: .trailing))
            }
            if cameraModel.isRecording && cameraModel.isVideoFlashOn && cameraModel.currentCameraPosition == .front {
                Color.white.ignoresSafeArea().opacity(0.5).brightness(0.6)
            }
            if showPhotoFlash {
                Color.white.ignoresSafeArea().brightness(10.0)
            }
            if cameraModel.capturedImage != nil {
                imagePreview().transition(.move(edge: .trailing))
            }
        })
        .alert("Discard Media", isPresented: $closeAlert) {
            Button("Done", role: .destructive) {
                cameraModel.recordedURLs.removeAll()
                cameraModel.recordedDuration = 0
                cameraModel.previewURL = nil
                cameraModel.capturedImage = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    cameraModel.removeAudio()
                }
                presentationMode.wrappedValue.dismiss()
            }
            Button("Retake", role: .destructive) {
                cameraModel.recordedURLs.removeAll()
                cameraModel.recordedDuration = 0
                cameraModel.previewURL = nil
                cameraModel.capturedImage = nil
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Discard Media and Switch Camera Mode?", isPresented: $askSwitch) {
            Button("Discard and Switch", role: .destructive) {
                cameraModel.recordedURLs.removeAll()
                cameraModel.recordedDuration = 0
                cameraModel.previewURL = nil
                cameraModel.capturedImage = nil
                withAnimation {
                    cameraModel.photoMode = true
                }
            }
            Button("Keep", role: .cancel) { }
        }
        .animation(.easeInOut, value: cameraModel.showPreview)
        .preferredColorScheme(.dark)
    }
    func imagePreview() -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let image = cameraModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .offset(y: -(top_Inset() / 2))
            }
            VStack {
                Spacer()
                ZStack(alignment: .top){
                    Rectangle().cornerRadius(30, corners: [.topLeft, .topRight]).foregroundStyle(.ultraThinMaterial)
                    HStack(spacing: 5){
                        Menu {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)){
                                    savedPhoto = true
                                }
                                if let image = cameraModel.capturedImage {
                                    saveUIImage(image: image)
                                }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }, label: {
                                Label("Save to Photos", systemImage: "square.and.arrow.down")
                            })
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.2)){
                                    savedPhoto = true
                                }
                                if !savedMemory {
                                    savedMemory = true
                                    if let image = cameraModel.capturedImage {
                                        ImageUploader.uploadImage(image: image, location: "memories", compression: 0.15) { loc, _ in
                                            if !loc.isEmpty {
                                                popRoot.alertReason = "Memory Saved"
                                                popRoot.alertImage = "checkmark"
                                                withAnimation(.easeInOut(duration: 0.2)){
                                                    popRoot.showAlert = true
                                                }
                                                
                                                let newID = UUID().uuidString
                                                var lat: CGFloat? = nil
                                                var long: CGFloat? = nil
                                                if let current = globe.currentLocation {
                                                    lat = CGFloat(current.lat)
                                                    long = CGFloat(current.long)
                                                } else if let current = auth.currentUser?.currentLocation, let place = extractLatLong(from: current) {
                                                    lat = place.latitude
                                                    long = place.longitude
                                                }
                                                UserService().saveMemories(docID: newID, imageURL: loc, videoURL: nil, lat: lat, long: long)
                                                let new = animatableMemory(isImage: true, memory: Memory(id: newID, image: loc, lat: lat, long: long, createdAt: Timestamp()))
                                                if let idx = popRoot.allMemories.firstIndex(where: { $0.date == "Recents" }) {
                                                    popRoot.allMemories[idx].allMemories.insert(new, at: 0)
                                                } else {
                                                    let newMonth = MemoryMonths(date: "Recents", allMemories: [new])
                                                    popRoot.allMemories.insert(newMonth, at: 0)
                                                }
                                            } else {
                                                popRoot.alertReason = "Memory Save Error!"
                                                popRoot.alertImage = "exclamationmark.bubble.fill"
                                                withAnimation(.easeInOut(duration: 0.2)){
                                                    popRoot.showAlert = true
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    popRoot.alertReason = "Memory Saved"
                                    popRoot.alertImage = "checkmark"
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        popRoot.showAlert = true
                                    }
                                }
                            }, label: {
                                Label("Save to Memories", image: "memory")
                            })
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50).foregroundStyle(Color(UIColor.lightGray))
                                Image(systemName: savedPhoto ? "checkmark.icloud" : "square.and.arrow.down")
                                    .contentTransition(.symbolEffect(.replace))
                                    .foregroundStyle(savedPhoto ? .blue : .white)
                                    .font(.system(size: 20)).bold()
                                    .offset(y: savedPhoto ? 0 : -3)
                            }
                        }.frame(width: 45)
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation {
                                cameraModel.capturedImage = nil
                            }
                            savedPhoto = false
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50).foregroundStyle(Color(UIColor.lightGray))
                                Text("Retake")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 18)).bold()
                            }
                        }
                        Button {
                            if let image = cameraModel.capturedImage {
                                uploadCont.append(uploadContent(isImage: true, selectedImage: image, hustleImage: Image(uiImage: image)))
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            isImagePickerPresented = false
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50).foregroundStyle(.blue.opacity(0.6))
                                HStack {
                                    Text("Attach")
                                        .font(.system(size: 18)).bold()
                                    Image(systemName: "arrowtriangle.right.fill")
                                        .font(.system(size: 16)).bold()
                                }.foregroundStyle(.white)
                            }
                        }
                    }.frame(height: 40).padding(6).padding(.horizontal)
                }.frame(height: 95)
            }.ignoresSafeArea()
        }
    }
    func videoPreview() -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ZStack(alignment: .topTrailing){
                if let url = cameraModel.previewURL {
                    HustleVideoPlayerX(url: url, muted: $muted, currentTime: $currentTime, totalLength: $totalLength, playVid: .constant(false), pauseVid: .constant(false), shouldPlayAppear: true)
                        .offset(y: -(top_Inset() / 2))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .ignoresSafeArea(.keyboard)
                        .highPriorityGesture(
                            TapGesture().onEnded { loc in }
                        )
                }
                Button(action: {
                    muted.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label: {
                    ZStack {
                        Circle().foregroundStyle(.ultraThickMaterial)
                        if muted {
                            Image(systemName: "speaker.slash.fill").foregroundStyle(.white).font(.headline)
                        } else {
                            Image(systemName: "speaker.wave.2").foregroundStyle(.white).font(.headline)
                        }
                    }.frame(width: 40, height: 40)
                }).padding()
            }

            VStack {
                Spacer()
                ZStack(alignment: .top){
                    Rectangle().cornerRadius(30, corners: [.topLeft, .topRight]).foregroundStyle(.ultraThinMaterial)
                    HStack(spacing: 5){
                        Menu {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)){
                                    savedPhoto = true
                                }
                                if let url = cameraModel.previewURL {
                                    PHPhotoLibrary.shared().performChanges({
                                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                                    }) { saved, error in }
                                }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }, label: {
                                Label("Save to Photos", systemImage: "square.and.arrow.down")
                            })
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.2)){
                                    savedPhoto = true
                                }
                                if let url = cameraModel.previewURL, !savedMemory {
                                    savedMemory = true
                                    ImageUploader.uploadVideoToFB(localVideoURL: url) { opLoc in
                                        if let video = opLoc {
                                            popRoot.alertReason = "Memory Saved"
                                            popRoot.alertImage = "checkmark"
                                            withAnimation(.easeInOut(duration: 0.2)){
                                                popRoot.showAlert = true
                                            }
                                            
                                            let newID = UUID().uuidString
                                            var lat: CGFloat? = nil
                                            var long: CGFloat? = nil
                                            if let current = globe.currentLocation {
                                                lat = CGFloat(current.lat)
                                                long = CGFloat(current.long)
                                            } else if let current = auth.currentUser?.currentLocation, let place = extractLatLong(from: current) {
                                                lat = place.latitude
                                                long = place.longitude
                                            }
                                            UserService().saveMemories(docID: newID, imageURL: nil, videoURL: video, lat: lat, long: long)
                                            let new = animatableMemory(isImage: false, player: AVPlayer(url: url), memory: Memory(id: newID, video: video, lat: lat, long: long, createdAt: Timestamp()))
                                            if let idx = popRoot.allMemories.firstIndex(where: { $0.date == "Recents" }) {
                                                popRoot.allMemories[idx].allMemories.insert(new, at: 0)
                                            } else {
                                                let newMonth = MemoryMonths(date: "Recents", allMemories: [new])
                                                popRoot.allMemories.insert(newMonth, at: 0)
                                            }
                                        } else {
                                            popRoot.alertReason = "Memory Save Error!"
                                            popRoot.alertImage = "exclamationmark.bubble.fill"
                                            withAnimation(.easeInOut(duration: 0.2)){
                                                popRoot.showAlert = true
                                            }
                                        }
                                    }
                                } else {
                                    popRoot.alertReason = "Memory Saved"
                                    popRoot.alertImage = "checkmark"
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        popRoot.showAlert = true
                                    }
                                }
                            }, label: {
                                Label("Save to Memories", image: "memory")
                            })
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50).foregroundStyle(Color(UIColor.lightGray))
                                Image(systemName: savedPhoto ? "checkmark.icloud" : "square.and.arrow.down")
                                    .contentTransition(.symbolEffect(.replace))
                                    .foregroundStyle(savedPhoto ? .blue : .white)
                                    .font(.system(size: 20)).bold()
                                    .offset(y: savedPhoto ? 0 : -3)
                            }
                        }.frame(width: 45)
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation {
                                cameraModel.showPreview = false
                            }
                            savedPhoto = false
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50).foregroundStyle(Color(UIColor.lightGray))
                                Text("Back")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 18)).bold()
                            }
                        }
                        Button {
                            uploadCont.append(uploadContent(isImage: false, videoURL: cameraModel.previewURL))
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            isImagePickerPresented = false
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50).foregroundStyle(.blue.opacity(0.6))
                                HStack {
                                    Text("Attach")
                                        .font(.system(size: 18)).bold()
                                    Image(systemName: "arrowtriangle.right.fill")
                                        .font(.system(size: 16)).bold()
                                }.foregroundStyle(.white)
                            }
                        }
                    }.frame(height: 40).padding(6).padding(.horizontal)
                }.frame(height: 95)
            }.ignoresSafeArea()
        }
    }
    func modePicker() -> some View {
        ZStack {
            Capsule().foregroundStyle(.ultraThinMaterial).frame(width: 75, height: 40)
            Button {
                if !cameraModel.photoMode && cameraModel.previewURL != nil {
                    askSwitch = true
                } else {
                    withAnimation {
                        cameraModel.photoMode.toggle()
                    }
                }
            } label: {
                Text("Photo").font(.body).bold()
            }.offset(y: cameraModel.photoMode ? 0 : -50)
            Button {
                if !cameraModel.photoMode && cameraModel.previewURL != nil {
                    askSwitch = true
                } else {
                    withAnimation {
                        cameraModel.photoMode.toggle()
                    }
                }
            } label: {
                Text("Video").font(.body).bold()
            }.offset(y: cameraModel.photoMode ? 50 : 0)
        }
    }
}

struct UploadHustleCamera: View {
    @Binding var selectedImage: UIImage?
    @Binding var hustleImage: Image?
    @Binding var selectedVideoURL: URL?
    @Binding var isImagePickerPresented: Bool
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var globe: GlobeViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @StateObject var cameraModel = UploadCameraViewModel()
    @GestureState private var scale: CGFloat = 1.0
    @State private var previousScale: CGFloat = 1.0
    @State var focusLocation: FocusLocation?
    @State var closeAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @State var showPhotoFlash: Bool = false
    @State var isPhotoFlashOn: Bool = false
    @State var takingPhoto: Bool = false
    @State var askSwitch: Bool = false
    @State private var showPreviewSec = false
    @State var savedPhoto = false
    @State var muted = false
    @State private var currentTime: Double = 0.0
    @State private var totalLength: Double = 1.0
    
    @State private var closeNow = false
    @State var viewOffset: CGFloat = 0.0
    @State var dismissOpacity: CGFloat = 0.0
    @State private var savedMemory = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            UploadCameraStoryView()
                .environmentObject(cameraModel)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay(content: {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(.gray, lineWidth: 1.0).opacity(0.5)
                })
                .padding(.top,10)
                .padding(.bottom,30)
                .onTapGesture(count: 2) {
                    cameraModel.switchCamera()
                }
                .onTapGesture(count: 1) { tapP in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    focusLocation = FocusLocation(x: tapP.x, y: tapP.y)
                    cameraModel.focus(at: CGPoint(x: tapP.x, y: tapP.y))
                }
                .offset(y: viewOffset)
                .gesture(DragGesture()
                    .onChanged({ val in
                        if !cameraModel.isRecording {
                            if (val.translation.height > 0.0 && val.translation.height < 90.0) || (viewOffset >= 0.0 && viewOffset < 90.0) {
                                viewOffset = val.translation.height
                                
                                dismissOpacity = viewOffset / 130.0
                                
                                if viewOffset > 80.0 {
                                    if !closeNow {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        closeNow = true
                                    }
                                } else if closeNow {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    closeNow = false
                                }
                            }
                        }
                    })
                    .onEnded({ val in
                        if val.translation.height > 80.0 {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewOffset = widthOrHeight(width: false)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isImagePickerPresented = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                cameraModel.removeAudio()
                            }
                        } else {
                            closeNow = false
                            withAnimation(.easeInOut(duration: 0.2)) {
                                dismissOpacity = 0.0
                                viewOffset = 0.0
                            }
                        }
                    })
                )
                .gesture(MagnificationGesture()
                    .updating($scale, body: { (value, state, _) in
                        state = value
                    })
                    .onChanged { value in
                        let delta = value / previousScale
                        cameraModel.zoom(delta)
                        previousScale = value
                    }
                    .onEnded { _ in
                        previousScale = 1.0
                    }
                )
            let w = widthOrHeight(width: true)
            let h = widthOrHeight(width: false)
            if let points = focusLocation, (points.x > 20) && (points.x < w - 20) && (points.y > 80) && (points.y < h - (h * 0.3)) {
                FocusView()
                    .position(x: points.x, y: points.y)
                    .task {
                        do {
                            try await Task.sleep(for: .milliseconds(750))
                            self.focusLocation = nil
                        } catch { }
                    }
                    .id(points.id)
            }
            
            HStack {
                VStack {
                    Button {
                        if cameraModel.previewURL == nil && cameraModel.capturedImage == nil {
                            cameraModel.removeAudio()
                            isImagePickerPresented = false
                        } else {
                            closeAlert.toggle()
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        ZStack {
                            Circle().frame(width: 47, height: 47)
                                .foregroundStyle(viewOffset > 80.0 ? Color.white : Color.black.opacity(0.7))
                            Image(systemName: "xmark")
                                .foregroundColor(viewOffset > 80.0 ? .black : .white)
                        }
                    }
                    Spacer()
                }
                Spacer()
                VStack {
                    Text("Dismiss")
                        .padding(.top, 10)
                        .font(.title3).bold().foregroundStyle(.white)
                        .opacity(viewOffset > 80.0 ? 1.0 : dismissOpacity)
                    Spacer()
                }
                Spacer()
                VStack {
                    Button {
                        cameraModel.switchCamera()
                    } label: {
                        ZStack {
                            Circle().frame(width: 47, height: 47).foregroundStyle(Color.black.opacity(0.7))
                            Image(systemName: "arrow.triangle.2.circlepath.camera").foregroundColor(.white)
                        }
                    }
                    Button {
                        if cameraModel.photoMode {
                            isPhotoFlashOn.toggle()
                        } else {
                            cameraModel.isVideoFlashOn.toggle()
                            
                            if cameraModel.isVideoFlashOn && cameraModel.isRecording && cameraModel.currentCameraPosition == .back {
                                cameraModel.flashSelect(on: true)
                            } else if !cameraModel.isVideoFlashOn {
                                cameraModel.flashSelect(on: false)
                            }
                        }
                    } label: {
                        ZStack {
                            Circle().frame(width: 47, height: 47).foregroundStyle(Color.black.opacity(0.7))
                            Image(systemName: (cameraModel.photoMode && isPhotoFlashOn) || (!cameraModel.photoMode && cameraModel.isVideoFlashOn) ? "bolt.fill" : "bolt")
                                .foregroundColor((cameraModel.photoMode && isPhotoFlashOn) || (!cameraModel.photoMode && cameraModel.isVideoFlashOn) ? .yellow : .white)
                        }
                    }.padding(.top, 4)
                    Spacer()
                }
                .opacity(viewOffset == 0.0 ? 1.0 : 0.0)
                .animation(.easeIn, value: viewOffset)
            }.padding(.horizontal).padding(.top, 35).font(.system(size: 23))
            
            Button {
                if cameraModel.photoMode {
                    takingPhoto = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                        takingPhoto = false
                    }
                    if isPhotoFlashOn {
                        if cameraModel.currentCameraPosition == .back {
                            cameraModel.flashSelect(on: true)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                                cameraModel.flashSelect(on: false)
                            }
                        } else {
                            showPhotoFlash = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                                showPhotoFlash = false
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            cameraModel.takePhoto()
                        }
                    } else {
                        cameraModel.takePhoto()
                    }
                } else {
                    if cameraModel.isRecording {
                        cameraModel.stopRecording(shouldToggle: true)
                        cameraModel.flashSelect(on: false)
                    } else {
                        if cameraModel.currentCameraPosition == .back && cameraModel.isVideoFlashOn {
                            cameraModel.flashSelect(on: true)
                        }
                        cameraModel.startRecording()
                    }
                }
            } label: {
                if cameraModel.isRecording {
                    RoundedRectangle(cornerRadius: 8)
                        .frame(width: 65, height: 65).foregroundStyle(.red).opacity(0.7)
                        .padding(.bottom, 15)
                } else {
                    ZStack {
                        Color.gray.opacity(0.001)
                        Circle().stroke(.white, lineWidth: 7).frame(width: 80, height: 80)
                    }.frame(width: 95, height: 95)
                }
            }
            .padding(.bottom, 70).disabled(takingPhoto)
            .opacity(viewOffset == 0.0 ? 1.0 : 0.0)
            .animation(.easeIn, value: viewOffset)
            
            HStack {
                if !cameraModel.isRecording {
                    modePicker()
                }
                Spacer()
                if !cameraModel.photoMode && !cameraModel.isRecording && !cameraModel.recordedURLs.isEmpty {
                    Button {
                        if let _ = cameraModel.previewURL {
                            cameraModel.removeAudio()
                            cameraModel.showPreview.toggle()
                        }
                    } label: {
                        if cameraModel.previewURL == nil {
                            ZStack {
                                Circle().frame(width: 47, height: 47).foregroundStyle(Color(UIColor.lightGray))
                                ProgressView().tint(.black)
                            }.padding(.trailing, 20)
                        } else {
                            HStack {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .padding(10)
                            .foregroundColor(.white).font(.body)
                            .background {
                                Capsule().foregroundStyle(.ultraThinMaterial)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 95).padding(.horizontal)
            .opacity(viewOffset == 0.0 ? 1.0 : 0.0)
            .animation(.easeIn, value: viewOffset)
        }
        .overlay(content: {
            if cameraModel.previewURL != nil && cameraModel.showPreview {
                videoPreview().transition(.move(edge: .trailing))
            }
            if cameraModel.isRecording && cameraModel.isVideoFlashOn && cameraModel.currentCameraPosition == .front {
                Color.white.ignoresSafeArea().opacity(0.5).brightness(0.6)
            }
            if showPhotoFlash {
                Color.white.ignoresSafeArea().brightness(10.0)
            }
            if cameraModel.capturedImage != nil {
                imagePreview().transition(.move(edge: .trailing))
            }
        })
        .alert("Discard Media", isPresented: $closeAlert) {
            Button("Done", role: .destructive) {
                cameraModel.recordedURLs.removeAll()
                cameraModel.recordedDuration = 0
                cameraModel.previewURL = nil
                cameraModel.capturedImage = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    cameraModel.removeAudio()
                }
                presentationMode.wrappedValue.dismiss()
            }
            Button("Retake", role: .destructive) {
                cameraModel.recordedURLs.removeAll()
                cameraModel.recordedDuration = 0
                cameraModel.previewURL = nil
                cameraModel.capturedImage = nil
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Discard Media and Switch Camera Mode?", isPresented: $askSwitch) {
            Button("Discard and Switch", role: .destructive) {
                cameraModel.recordedURLs.removeAll()
                cameraModel.recordedDuration = 0
                cameraModel.previewURL = nil
                cameraModel.capturedImage = nil
                withAnimation {
                    cameraModel.photoMode = true
                }
            }
            Button("Keep", role: .cancel) { }
        }
        .animation(.easeInOut, value: cameraModel.showPreview)
        .preferredColorScheme(.dark)
    }
    func imagePreview() -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let image = cameraModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .offset(y: -(top_Inset() / 2))
            }
            VStack {
                Spacer()
                ZStack(alignment: .top){
                    Rectangle().cornerRadius(30, corners: [.topLeft, .topRight]).foregroundStyle(.ultraThinMaterial)
                    HStack(spacing: 5){
                        Menu {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)){
                                    savedPhoto = true
                                }
                                if let image = cameraModel.capturedImage {
                                    saveUIImage(image: image)
                                }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }, label: {
                                Label("Save to Photos", systemImage: "square.and.arrow.down")
                            })
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.2)){
                                    savedPhoto = true
                                }
                                if !savedMemory {
                                    savedMemory = true
                                    if let image = cameraModel.capturedImage {
                                        ImageUploader.uploadImage(image: image, location: "memories", compression: 0.15) { loc, _ in
                                            if !loc.isEmpty {
                                                popRoot.alertReason = "Memory Saved"
                                                popRoot.alertImage = "checkmark"
                                                withAnimation(.easeInOut(duration: 0.2)){
                                                    popRoot.showAlert = true
                                                }
                                                
                                                let newID = UUID().uuidString
                                                var lat: CGFloat? = nil
                                                var long: CGFloat? = nil
                                                if let current = globe.currentLocation {
                                                    lat = CGFloat(current.lat)
                                                    long = CGFloat(current.long)
                                                } else if let current = auth.currentUser?.currentLocation, let place = extractLatLong(from: current) {
                                                    lat = place.latitude
                                                    long = place.longitude
                                                }
                                                UserService().saveMemories(docID: newID, imageURL: loc, videoURL: nil, lat: lat, long: long)
                                                let new = animatableMemory(isImage: true, memory: Memory(id: newID, image: loc, lat: lat, long: long, createdAt: Timestamp()))
                                                if let idx = popRoot.allMemories.firstIndex(where: { $0.date == "Recents" }) {
                                                    popRoot.allMemories[idx].allMemories.insert(new, at: 0)
                                                } else {
                                                    let newMonth = MemoryMonths(date: "Recents", allMemories: [new])
                                                    popRoot.allMemories.insert(newMonth, at: 0)
                                                }
                                            } else {
                                                popRoot.alertReason = "Memory Save Error!"
                                                popRoot.alertImage = "exclamationmark.bubble.fill"
                                                withAnimation(.easeInOut(duration: 0.2)){
                                                    popRoot.showAlert = true
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    popRoot.alertReason = "Memory Saved"
                                    popRoot.alertImage = "checkmark"
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        popRoot.showAlert = true
                                    }
                                }
                            }, label: {
                                Label("Save to Memories", image: "memory")
                            })
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50).foregroundStyle(Color(UIColor.lightGray))
                                Image(systemName: savedPhoto ? "checkmark.icloud" : "square.and.arrow.down")
                                    .contentTransition(.symbolEffect(.replace))
                                    .foregroundStyle(savedPhoto ? .blue : .white)
                                    .font(.system(size: 20)).bold()
                                    .offset(y: savedPhoto ? 0 : -3)
                            }
                        }.frame(width: 45)
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)){
                                cameraModel.capturedImage = nil
                            }
                            savedPhoto = false
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50).foregroundStyle(Color(UIColor.lightGray))
                                Text("Retake")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 18)).bold()
                            }
                        }
                        Button {
                            if let image = cameraModel.capturedImage {
                                selectedImage = image
                                hustleImage = Image(uiImage: image)
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            isImagePickerPresented = false
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50).foregroundStyle(.blue.opacity(0.6))
                                HStack {
                                    Text("Attach")
                                        .font(.system(size: 18)).bold()
                                    Image(systemName: "arrowtriangle.right.fill")
                                        .font(.system(size: 16)).bold()
                                }.foregroundStyle(.white)
                            }
                        }
                    }.frame(height: 40).padding(6).padding(.horizontal)
                }.frame(height: 95)
            }.ignoresSafeArea()
        }
    }
    func videoPreview() -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ZStack(alignment: .topTrailing){
                if let url = cameraModel.previewURL {
                    HustleVideoPlayerX(url: url, muted: $muted, currentTime: $currentTime, totalLength: $totalLength, playVid: .constant(false), pauseVid: .constant(false), shouldPlayAppear: true)
                        .offset(y: -(top_Inset() / 2))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .ignoresSafeArea(.keyboard)
                        .highPriorityGesture(
                            TapGesture().onEnded { loc in }
                        )
                }
                Button(action: {
                    muted.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label: {
                    ZStack {
                        Circle().foregroundStyle(.ultraThickMaterial)
                        if muted {
                            Image(systemName: "speaker.slash.fill").foregroundStyle(.white).font(.headline)
                        } else {
                            Image(systemName: "speaker.wave.2").foregroundStyle(.white).font(.headline)
                        }
                    }.frame(width: 40, height: 40)
                }).padding()
            }

            VStack {
                Spacer()
                ZStack(alignment: .top){
                    Rectangle().cornerRadius(30, corners: [.topLeft, .topRight]).foregroundStyle(.ultraThinMaterial)
                    HStack(spacing: 5){
                        Menu {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)){
                                    savedPhoto = true
                                }
                                if let url = cameraModel.previewURL {
                                    PHPhotoLibrary.shared().performChanges({
                                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                                    }) { saved, error in }
                                }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }, label: {
                                Label("Save to Photos", systemImage: "square.and.arrow.down")
                            })
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.2)){
                                    savedPhoto = true
                                }
                                if let url = cameraModel.previewURL, !savedMemory {
                                    savedMemory = true
                                    ImageUploader.uploadVideoToFB(localVideoURL: url) { opLoc in
                                        if let video = opLoc {
                                            popRoot.alertReason = "Memory Saved"
                                            popRoot.alertImage = "checkmark"
                                            withAnimation(.easeInOut(duration: 0.2)){
                                                popRoot.showAlert = true
                                            }
                                            
                                            let newID = UUID().uuidString
                                            var lat: CGFloat? = nil
                                            var long: CGFloat? = nil
                                            if let current = globe.currentLocation {
                                                lat = CGFloat(current.lat)
                                                long = CGFloat(current.long)
                                            } else if let current = auth.currentUser?.currentLocation, let place = extractLatLong(from: current) {
                                                lat = place.latitude
                                                long = place.longitude
                                            }
                                            UserService().saveMemories(docID: newID, imageURL: nil, videoURL: video, lat: lat, long: long)
                                            let new = animatableMemory(isImage: false, player: AVPlayer(url: url), memory: Memory(id: newID, video: video, lat: lat, long: long, createdAt: Timestamp()))
                                            if let idx = popRoot.allMemories.firstIndex(where: { $0.date == "Recents" }) {
                                                popRoot.allMemories[idx].allMemories.insert(new, at: 0)
                                            } else {
                                                let newMonth = MemoryMonths(date: "Recents", allMemories: [new])
                                                popRoot.allMemories.insert(newMonth, at: 0)
                                            }
                                        } else {
                                            popRoot.alertReason = "Memory Save Error!"
                                            popRoot.alertImage = "exclamationmark.bubble.fill"
                                            withAnimation(.easeInOut(duration: 0.2)){
                                                popRoot.showAlert = true
                                            }
                                        }
                                    }
                                } else {
                                    popRoot.alertReason = "Memory Saved"
                                    popRoot.alertImage = "checkmark"
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        popRoot.showAlert = true
                                    }
                                }
                            }, label: {
                                Label("Save to Memories", image: "memory")
                            })
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50).foregroundStyle(Color(UIColor.lightGray))
                                Image(systemName: savedPhoto ? "checkmark.icloud" : "square.and.arrow.down")
                                    .contentTransition(.symbolEffect(.replace))
                                    .foregroundStyle(savedPhoto ? .blue : .white)
                                    .font(.system(size: 20)).bold()
                                    .offset(y: savedPhoto ? 0 : -3)
                            }
                        }.frame(width: 45)
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)){
                                cameraModel.showPreview = false
                            }
                            savedPhoto = false
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50).foregroundStyle(Color(UIColor.lightGray))
                                Text("Back")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 18)).bold()
                            }
                        }
                        Button {
                            selectedVideoURL = cameraModel.previewURL
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            isImagePickerPresented = false
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50).foregroundStyle(.blue.opacity(0.6))
                                HStack {
                                    Text("Attach")
                                        .font(.system(size: 18)).bold()
                                    Image(systemName: "arrowtriangle.right.fill")
                                        .font(.system(size: 16)).bold()
                                }.foregroundStyle(.white)
                            }
                        }
                    }.frame(height: 40).padding(6).padding(.horizontal)
                }.frame(height: 95)
            }.ignoresSafeArea()
        }
    }
    func modePicker() -> some View {
        ZStack {
            Capsule().foregroundStyle(.ultraThinMaterial).frame(width: 75, height: 40)
            Button {
                if !cameraModel.photoMode && cameraModel.previewURL != nil {
                    askSwitch = true
                } else {
                    withAnimation {
                        cameraModel.photoMode.toggle()
                    }
                }
            } label: {
                Text("Photo").font(.body).bold()
            }.offset(y: cameraModel.photoMode ? 0 : -50)
            Button {
                if !cameraModel.photoMode && cameraModel.previewURL != nil {
                    askSwitch = true
                } else {
                    withAnimation {
                        cameraModel.photoMode.toggle()
                    }
                }
            } label: {
                Text("Video").font(.body).bold()
            }.offset(y: cameraModel.photoMode ? 50 : 0)
        }
    }
}

struct UploadCameraStoryView: View {
    @EnvironmentObject var cameraModel: UploadCameraViewModel
    var body: some View {
        
        GeometryReader { proxy in
            let size = proxy.size
            
            UploadCameraPreview(size: size).environmentObject(cameraModel)
            
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

struct UploadCameraPreview: UIViewRepresentable {
    @EnvironmentObject var cameraModel : UploadCameraViewModel
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


class UploadCameraViewModel: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate, AVCapturePhotoCaptureDelegate {
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
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            if self.session.canAddInput(audioInput){
                self.session.addInput(audioInput)
            }
            
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

import SwiftUI
import AVKit
import AVFoundation
import Kingfisher

struct messageSendType: Identifiable, Hashable {
    var id: String
    var title: String
    var type: Int
}

struct MessageCamera: View {
    @StateObject var cameraModel = CameraViewModel()
    @GestureState private var scale: CGFloat = 1.0
    @State private var previousScale: CGFloat = 1.0
    @State var focusLocation: FocusLocation?
    @State var closeAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @State var showPhotoFlash: Bool = false
    @State var isPhotoFlashOn: Bool = false
    @State var takingPhoto: Bool = false
    @State var askSwitch: Bool = false
    @State private var isImagePickerPresented = false
    @State var selectedVideoURL: URL?
    @State private var showPreviewSec = false
    @Binding var initialSend: messageSendType?
    
    @State private var closeNow = false
    @State var viewOffset: CGFloat = 0.0
    @State var dismissOpacity: CGFloat = 0.0
    let showMemories: Bool
    @State var showMemorySheet = false
    
    @State var memoryImage: String?
    @State var memoryVideo: URL?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            CameraStoryView()
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
                                presentationMode.wrappedValue.dismiss()
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
                            presentationMode.wrappedValue.dismiss()
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
                VStack(spacing: 15){
                    Button {
                        cameraModel.switchCamera()
                    } label: {
                        ZStack {
                            Circle().foregroundStyle(Color.black.opacity(0.7))
                            Image(systemName: "arrow.triangle.2.circlepath.camera").foregroundColor(.white)
                        }
                    }.frame(width: 47, height: 47)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if cameraModel.photoMode {
                            withAnimation(.easeInOut(duration: 0.3)){
                                isPhotoFlashOn.toggle()
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)){
                                cameraModel.isVideoFlashOn.toggle()
                            }
                            
                            if cameraModel.isVideoFlashOn && cameraModel.isRecording && cameraModel.currentCameraPosition == .back {
                                cameraModel.flashSelect(on: true)
                            } else if !cameraModel.isVideoFlashOn {
                                cameraModel.flashSelect(on: false)
                            }
                        }
                    } label: {
                        ZStack {
                            Circle().foregroundStyle(Color.black.opacity(0.7))
                            Image(systemName: (cameraModel.photoMode && isPhotoFlashOn) || (!cameraModel.photoMode && cameraModel.isVideoFlashOn) ? "bolt.fill" : "bolt.slash")
                                .contentTransition(.symbolEffect(.replace))
                                .foregroundColor((cameraModel.photoMode && isPhotoFlashOn) || (!cameraModel.photoMode && cameraModel.isVideoFlashOn) ? .yellow : .white)
                        }
                    }.frame(width: 47, height: 47)
                    Button {
                        isImagePickerPresented.toggle()
                    } label: {
                        ZStack {
                            Circle().foregroundStyle(Color.black.opacity(0.7))
                            Image(systemName: "photo.on.rectangle.angled").foregroundColor(.white)
                        }
                    }
                    .frame(width: 47, height: 47)
                    .disabled(cameraModel.isRecording)
                    .fullScreenCover(isPresented: $isImagePickerPresented, content: {
                        ImagePickerView(selectedImage: $cameraModel.capturedImage, selectedVideoURL: $selectedVideoURL, isImagePickerPresented: $isImagePickerPresented, showPreviewSec: $showPreviewSec)
                    })
                    if showMemories {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showMemorySheet = true
                        } label: {
                            ZStack {
                                Circle().foregroundStyle(Color.black.opacity(0.7))
                                Image("memory")
                                    .resizable()
                                    .scaledToFit()
                            }
                        }.frame(width: 47, height: 47)
                    }
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
                            let resetTo = setMaxBrightness()
                            showPhotoFlash = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                showPhotoFlash = false
                                resetBrightness(reset: resetTo)
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
                        .opacity(viewOffset == 0.0 ? 1.0 : 0.0)
                        .animation(.easeIn, value: viewOffset)
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
                    .opacity(viewOffset == 0.0 ? 1.0 : 0.0)
                    .animation(.easeIn, value: viewOffset)
                }
            }.padding(.bottom, 95).padding(.horizontal)
        }
        .sheet(isPresented: $showMemorySheet, content: {
            MemoryPickerSheetView(photoOnly: false, maxSelect: 1) { returnedData in
                if let first = returnedData.first {
                    withAnimation(.easeInOut(duration: 0.15)){
                        if first.isImage {
                            memoryImage = first.urlString
                        } else {
                            memoryVideo = URL(string: first.urlString)
                        }
                    }
                }
            }
        })
        .overlay(content: {
            if let url = cameraModel.previewURL, cameraModel.showPreview {
                VideoPreviewMessage(url: url, showPreview: $cameraModel.showPreview, initialSend: $initialSend, isMain: false, memoryVideo: .constant(nil))
                    .transition(.move(edge: .trailing))
                    .onDisappear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            cameraModel.addAudio()
                        }
                    }
            } else if let url = selectedVideoURL, showPreviewSec {
                VideoPreviewMessage(url: url, showPreview: $showPreviewSec, initialSend: $initialSend, isMain: false, memoryVideo: .constant(nil))
                    .transition(.move(edge: .trailing))
                    .onAppear {
                        cameraModel.removeAudio()
                    }
                    .onDisappear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            cameraModel.addAudio()
                        }
                    }
            } else if let url = memoryVideo {
                VideoPreviewMessage(url: url, showPreview: $showPreviewSec, initialSend: $initialSend, isMain: false, memoryVideo: $memoryVideo)
                    .transition(.move(edge: .trailing))
                    .onAppear {
                        cameraModel.removeAudio()
                    }
                    .onDisappear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            cameraModel.addAudio()
                        }
                    }
            }
            
            if cameraModel.isRecording && cameraModel.isVideoFlashOn && cameraModel.currentCameraPosition == .front {
                Color.white.ignoresSafeArea().opacity(0.5).brightness(0.6)
            }
            if showPhotoFlash {
                Color.white.ignoresSafeArea().brightness(10.0)
            }
            if cameraModel.capturedImage != nil {
                ImagePreviewMessage(image: $cameraModel.capturedImage, initialSend: $initialSend, isMain: false, memoryImage: .constant(nil))
                    .transition(.move(edge: .trailing))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            cameraModel.removeAudio()
                        }
                    }
                    .onDisappear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            cameraModel.addAudio()
                        }
                    }
            } else if memoryImage != nil {
                ImagePreviewMessage(image: .constant(nil), initialSend: $initialSend, isMain: false, memoryImage: $memoryImage)
                    .transition(.move(edge: .trailing))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            cameraModel.removeAudio()
                        }
                    }
                    .onDisappear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            cameraModel.addAudio()
                        }
                    }
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

struct MessageCameraSec: View {
    @EnvironmentObject var v2: MessageViewModel
    @StateObject var cameraModel = CameraViewModel()
    @GestureState private var scale: CGFloat = 1.0
    @State private var previousScale: CGFloat = 1.0
    @State var focusLocation: FocusLocation?
    @State var closeAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @State var showPhotoFlash: Bool = false
    @State var isPhotoFlashOn: Bool = false
    @State var takingPhoto: Bool = false
    @State var askSwitch: Bool = false
    @State private var isImagePickerPresented = false
    @State var selectedVideoURL: URL?
    @State private var showPreviewSec = false
    
    @State var memoryImage: String?
    @State var memoryVideo: URL?
    
    @State private var closeNow = false
    @State private var showMemorySheet = false
    @Binding var option: Int
    @Binding var offset: CGFloat
    @Binding var content: Bool
    @Binding var isRecording: Bool
    let showMemories: Bool
    let close: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if option == 1 || offset > (widthOrHeight(width: true) * 0.5) {
                CameraStoryView()
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
            } else {
                GeometryReader(content: { geometry in
                    KFImage(URL(string: "https://images.pexels.com/photos/2049422/pexels-photo-2049422.jpeg?cs=srgb&dl=pexels-pok-rie-33563-2049422.jpg&fm=jpg"))
                        .resizable()
                        .scaledToFill()
                        .opacity(0.6)
                        .overlay {
                            TransparentBlurView(removeAllFilters: true)
                                .blur(radius: 24, opaque: true)
                                .background(.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                })
            }
            
            HStack {
                VStack {
                    Button {
                        if cameraModel.isRecording {
                            cameraModel.stopRecording(shouldToggle: true)
                            cameraModel.flashSelect(on: false)
                            isRecording = false
                        } else if cameraModel.previewURL == nil && cameraModel.capturedImage == nil {
                            close()
                        } else {
                            closeAlert.toggle()
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        ZStack {
                            Circle().frame(width: 47, height: 47)
                                .foregroundStyle(Color.black.opacity(0.7))
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                }
                Spacer()
                VStack(spacing: 15){
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        cameraModel.switchCamera()
                    } label: {
                        ZStack {
                            Circle().foregroundStyle(Color.black.opacity(0.7))
                            Image(systemName: "arrow.triangle.2.circlepath.camera").foregroundColor(.white)
                        }
                    }.frame(width: 47, height: 47)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if cameraModel.photoMode {
                            withAnimation(.easeInOut(duration: 0.2)){
                                isPhotoFlashOn.toggle()
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)){
                                cameraModel.isVideoFlashOn.toggle()
                            }
                            
                            if cameraModel.isVideoFlashOn && cameraModel.isRecording && cameraModel.currentCameraPosition == .back {
                                cameraModel.flashSelect(on: true)
                            } else if !cameraModel.isVideoFlashOn {
                                cameraModel.flashSelect(on: false)
                            }
                        }
                    } label: {
                        ZStack {
                            Circle().foregroundStyle(Color.black.opacity(0.7))
                            Image(systemName: (cameraModel.photoMode && isPhotoFlashOn) || (!cameraModel.photoMode && cameraModel.isVideoFlashOn) ? "bolt.fill" : "bolt.slash")
                                .contentTransition(.symbolEffect(.replace))
                                .foregroundColor((cameraModel.photoMode && isPhotoFlashOn) || (!cameraModel.photoMode && cameraModel.isVideoFlashOn) ? .yellow : .white)
                        }
                    }.frame(width: 47, height: 47)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        isImagePickerPresented.toggle()
                    } label: {
                        ZStack {
                            Circle().foregroundStyle(Color.black.opacity(0.7))
                            Image(systemName: "photo.on.rectangle.angled").foregroundColor(.white)
                        }
                    }
                    .frame(width: 47, height: 47)
                    .disabled(cameraModel.isRecording)
                    .fullScreenCover(isPresented: $isImagePickerPresented, content: {
                        ImagePickerView(selectedImage: $cameraModel.capturedImage, selectedVideoURL: $selectedVideoURL, isImagePickerPresented: $isImagePickerPresented, showPreviewSec: $showPreviewSec)
                    })
                    if showMemories {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showMemorySheet = true
                        } label: {
                            ZStack {
                                Circle().foregroundStyle(Color.black.opacity(0.7))
                                Image("memory")
                                    .resizable()
                                    .scaledToFit()
                            }
                        }.frame(width: 47, height: 47)
                    }
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
                            let resetTo = setMaxBrightness()
                            showPhotoFlash = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                showPhotoFlash = false
                                resetBrightness(reset: resetTo)
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
                        isRecording = false
                    } else {
                        cameraModel.addAudio()
                        if cameraModel.currentCameraPosition == .back && cameraModel.isVideoFlashOn {
                            cameraModel.flashSelect(on: true)
                        }
                        cameraModel.startRecording()
                        isRecording = true
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
            
            HStack {
                if !cameraModel.isRecording {
                    modePicker()
                }
                Spacer()
                if !cameraModel.photoMode && !cameraModel.isRecording && !cameraModel.recordedURLs.isEmpty {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
        .sheet(isPresented: $showMemorySheet, content: {
            MemoryPickerSheetView(photoOnly: false, maxSelect: 1) { returnedData in
                if let first = returnedData.first {
                    withAnimation(.easeInOut(duration: 0.15)){
                        if first.isImage {
                            memoryImage = first.urlString
                        } else {
                            memoryVideo = URL(string: first.urlString)
                        }
                    }
                }
            }
        })
        .padding(.bottom, bottom_Inset())
        .onChange(of: v2.navigateOut, { oldValue, newValue in
            close()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                cameraModel.recordedURLs.removeAll()
                cameraModel.recordedDuration = 0
                cameraModel.previewURL = nil
                cameraModel.capturedImage = nil
                showPreviewSec = false
                cameraModel.showPreview = false
                cameraModel.photoMode = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                cameraModel.removeAudio()
            }
        })
        .onChange(of: option, { oldValue, newValue in
            if oldValue == 1 && newValue != 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    cameraModel.removeAudio()
                }
            }
        })
        .onChange(of: cameraModel.capturedImage, { _, new in
            if new != nil {
                content = true
            } else {
                content = false
            }
        })
        .onChange(of: memoryImage, { _, new in
            if new != nil {
                content = true
            } else {
                content = false
            }
        })
        .onChange(of: cameraModel.showPreview, { _, new in
            if new {
                content = true
            } else {
                content = false
            }
        })
        .onChange(of: showPreviewSec, { _, new in
            if new {
                content = true
            } else {
                content = false
            }
        })
        .onChange(of: memoryVideo, { _, new in
            if new != nil {
                content = true
            } else {
                content = false
            }
        })
        .overlay(content: {
            if let url = cameraModel.previewURL, cameraModel.showPreview {
                VideoPreviewMessage(url: url, showPreview: $cameraModel.showPreview, initialSend: $v2.initialSend, isMain: true, memoryVideo: .constant(nil))
                    .transition(.move(edge: .trailing))
                    .onDisappear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            cameraModel.addAudio()
                        }
                    }
            } else if let url = selectedVideoURL, showPreviewSec {
                VideoPreviewMessage(url: url, showPreview: $showPreviewSec, initialSend: $v2.initialSend, isMain: true, memoryVideo: .constant(nil))
                    .transition(.move(edge: .trailing))
                    .onAppear {
                        cameraModel.removeAudio()
                    }
                    .onDisappear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            cameraModel.addAudio()
                        }
                    }
            } else if let url = memoryVideo {
                VideoPreviewMessage(url: url, showPreview: $showPreviewSec, initialSend: $v2.initialSend, isMain: true, memoryVideo: $memoryVideo)
                    .transition(.move(edge: .trailing))
                    .onAppear {
                        cameraModel.removeAudio()
                    }
                    .onDisappear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            cameraModel.addAudio()
                        }
                    }
            }
            if cameraModel.isRecording && cameraModel.isVideoFlashOn && cameraModel.currentCameraPosition == .front {
                Color.white.ignoresSafeArea().opacity(0.65).brightness(10.0)
            }
            if showPhotoFlash {
                Color.white.ignoresSafeArea().brightness(10.0)
            }
            if cameraModel.capturedImage != nil {
                ImagePreviewMessage(image: $cameraModel.capturedImage, initialSend: $v2.initialSend, isMain: true, memoryImage: .constant(nil))
                    .transition(.move(edge: .trailing))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            cameraModel.removeAudio()
                        }
                    }
                    .onDisappear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            cameraModel.addAudio()
                        }
                    }
            } else if memoryImage != nil {
                ImagePreviewMessage(image: .constant(nil), initialSend: $v2.initialSend, isMain: true, memoryImage: $memoryImage)
                    .transition(.move(edge: .trailing))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            cameraModel.removeAudio()
                        }
                    }
                    .onDisappear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            cameraModel.addAudio()
                        }
                    }
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
                close()
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
    }
    func modePicker() -> some View {
        ZStack {
            Capsule().foregroundStyle(.ultraThinMaterial).frame(width: 75, height: 40)
            Button {
                if !cameraModel.photoMode && cameraModel.previewURL != nil {
                    askSwitch = true
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.1)){
                        cameraModel.photoMode.toggle()
                    }
                }
            } label: {
                Text("Photo").font(.body).bold().foregroundStyle(.white)
            }.offset(y: cameraModel.photoMode ? 0 : -50)
            Button {
                if !cameraModel.photoMode && cameraModel.previewURL != nil {
                    askSwitch = true
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.1)){
                        cameraModel.photoMode.toggle()
                    }
                }
            } label: {
                Text("Video").font(.body).bold().foregroundStyle(.white)
            }.offset(y: cameraModel.photoMode ? 50 : 0)
        }
    }
}

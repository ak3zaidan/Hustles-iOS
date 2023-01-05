import SwiftUI
import Vision

struct SnapCameraHelper: View {
    @EnvironmentObject var pop: PopToRoot
    @ObservedObject var events = UserEvents()
    @Binding var inputMessage: String
    
    var body: some View {
        ZStack {
            if let image = pop.snapImage {
                SnapCamera(image: image, image2: .constant(nil), inputMessage: $inputMessage)
            } else {
                CameraView(events: events, applicationName: "Hustles").ignoresSafeArea()
                CameraInterfaceView(events: events)
            }
        }
    }
}

struct SnapCamera: View {
    @EnvironmentObject var pop: PopToRoot
    @EnvironmentObject var vm: ViewModel
    @State var caption: String = ""
    @State var imageText: String = ""
    @Environment(\.presentationMode) var presentationMode
    @State var savedPhoto: Bool = false
    @State var showError: Bool = false
    let image: UIImage?
    @Binding var image2: UIImage?
    @State var imageHeight: Double = 0.0
    @State var imageWidth: Double = 0.0
    @State var showPicker: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @Binding var inputMessage: String
    
    var body: some View {
        ZStack {
            if let image = image ?? image2 {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .offset(x: (widthOrHeight(width: true) - imageWidth) / 2.0, y: (widthOrHeight(width: false) - imageHeight) / 2.0)
                        .offset(y: -(top_Inset() / 2.0) + 8.0)
                        .background (
                            GeometryReader { proxy in
                                Color.clear
                                    .onAppear {
                                        imageHeight = proxy.size.height
                                        imageWidth = proxy.size.width
                                    }
                                    .onChange(of: image2) { _, _ in
                                        imageHeight = proxy.size.height
                                        imageWidth = proxy.size.width
                                    }
                            }
                        )
                }
                .ignoresSafeArea()
                .onAppear {
                    processImage(image: image) { str in
                        if let scanned = str, !scanned.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            imageText = scanned
                        } else {
                            showError = true
                        }
                    }
                }
            }
            VStack {
                HStack {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        presentationMode.wrappedValue.dismiss()
                        pop.snapImage = nil
                        savedPhoto = false
                    } label: {
                        Image(systemName: "xmark").font(.title).foregroundStyle(.white).bold()
                    }.padding(.leading, 20).padding(.top, 70)
                    Spacer()
                }
                Spacer()
                ZStack(alignment: .top){
                    Rectangle().cornerRadius(30, corners: [.topLeft, .topRight]).foregroundStyle(.ultraThinMaterial)
                    HStack(spacing: 5){
                        Button {
                            if !savedPhoto {
                                savedPhoto = true
                                if let image = image ?? image2 {
                                    saveUIImage(image: image)
                                }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50).foregroundStyle(Color(UIColor.lightGray))
                                if savedPhoto {
                                    Image(systemName: "checkmark.icloud")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 20)).bold()
                                } else {
                                    Image(systemName: "square.and.arrow.down")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 20)).bold()
                                        .offset(y: -3)
                                }
                            }
                        }.frame(width: 45)
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            if image == nil {
                                showPicker = true
                            } else {
                                pop.snapImage = nil
                                savedPhoto = false
                                caption = ""
                                imageText = ""
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50).foregroundStyle(Color(UIColor.lightGray))
                                Text("Retake")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 20)).bold()
                            }
                        }
                        Button {
                            presentationMode.wrappedValue.dismiss()
                            savedPhoto = false
                            pop.snapImage = nil
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            if vm.isInteracting {
                                vm.cancelStreamingResponse()
                            } else {
                                inputMessage = ""
                                Task { @MainActor in
                                    await vm.sendTapped(main: "", newText: caption, text2: imageText)
                                }
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50).foregroundStyle(.blue.opacity(0.6))
                                if vm.isInteracting {
                                    HStack {
                                        Text("AI Generating").font(.system(size: 20)).bold()
                                    }.foregroundStyle(.white)
                                } else {
                                    HStack {
                                        Text("Ask")
                                            .font(.system(size: 20)).bold()
                                        Image(systemName: "arrowtriangle.right.fill")
                                            .font(.system(size: 17)).bold()
                                    }.foregroundStyle(.white)
                                }
                            }
                        }
                    }.frame(height: 40).padding(6).padding(.horizontal)
                }.frame(height: 95)
            }.padding(.top, 8).ignoresSafeArea()
            keyboardImage().offset(y: widthOrHeight(width: false) * 0.2)
        }
        .onChange(of: image2) { _, _ in
            savedPhoto = false
            caption = ""
        }
        .sheet(isPresented: $showPicker, onDismiss: { } ){
            ImagePicker(selectedImage: $image2)
                .tint(colorScheme == .dark ? .white : .black)
        }
        .background(.black)
        .gesture (
            DragGesture()
                .onChanged { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
        .alert("Couldn't process image!", isPresented: $showError) {
            Button("Cancel", role: .cancel) {
                presentationMode.wrappedValue.dismiss()
                pop.snapImage = nil
                savedPhoto = false
            }
            Button("Retake", role: .destructive) {
                pop.snapImage = nil
                savedPhoto = false
                caption = ""
                imageText = ""
            }
        }
    }
    func keyboardImage() -> some View {
        ZStack(alignment: .leading){
            TextField("", text: $caption, axis: .vertical)
                .tint(.blue)
                .lineLimit(5)
                .padding(.vertical, 6)
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
                .background {
                    TransparentBlurView(removeAllFilters: true)
                        .blur(radius: 9, opaque: true)
                        .background(.black.opacity(0.4))
                }
                .cornerRadius(18, corners: .allCorners)
            if caption.isEmpty {
                Text("Caption...")
                    .foregroundStyle(.white)
                    .offset(x: 14)
                    .font(.system(size: 17))
            }
        }.padding(.horizontal, 25)
    }
}

struct CameraInterfaceView: View, CameraActions {
    @ObservedObject var events: UserEvents
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var pop: PopToRoot
    @State var flashOn: Bool = false
    
    var body: some View {
        ZStack {
            let w = widthOrHeight(width: true)
            let h = widthOrHeight(width: false)
            if let points = pop.focusLocation, (points.0 > 20) && (points.0 < w - 20) && (points.1 > 80) && (points.1 < h - (h * 0.3)) {
                FocusView()
                    .position(x: points.0, y: points.1 - 35)
                    .onAppear {
                        let p1 = points.0
                        Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false) { _ in
                            if (pop.focusLocation?.0 ?? 0.0) == p1 {
                                pop.focusLocation = nil
                            }
                        }
                    }
            }
            VStack {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        ZStack {
                            Color.gray.opacity(0.001)
                            Image(systemName: "xmark").font(.title).foregroundStyle(.white).bold()
                        }.frame(width: 60, height: 60)
                    }
                    Spacer()
                }.padding(.leading).padding(.top, 35)
                Spacer()
                HStack {
                    Button {
                        self.rotateCamera(events: events)
                    } label: {
                        ZStack {
                            Color.gray.opacity(0.001)
                            Image(systemName: "arrow.triangle.2.circlepath").font(.title2).foregroundStyle(.white).bold()
                        }.frame(width: 60, height: 60)
                    }
                    Spacer()
                    Button {
                        self.takePhoto(events: events)
                    } label: {
                        ZStack {
                            Color.gray.opacity(0.001)
                            Circle().stroke(.white, lineWidth: 7).frame(width: 80, height: 80)
                        }.frame(width: 95, height: 95)
                    }
                    Spacer()
                    Button {
                        self.changeFlashMode(events: events)
                        flashOn.toggle()
                    } label: {
                        ZStack {
                            Color.gray.opacity(0.001)
                            if flashOn {
                                Image(systemName: "bolt.fill").font(.title2).foregroundStyle(.yellow).bold()
                            } else {
                                Image(systemName: "bolt.slash.fill").font(.title2).foregroundStyle(.white).bold()
                            }
                        }.frame(width: 60, height: 60)
                    }
                }.padding(.bottom, 60).padding(.horizontal, 20)
            }
        }
    }
}

struct FocusView: View {
    @State var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.75))
                .frame(width: 70, height: 70)
                .scaleEffect(self.animate ? 1 : 0)
                .opacity(animate ? 0 : 1)
            
            Circle()
                .fill(.white)
                .frame(width: 7, height: 4)
                .scaleEffect(self.animate ? 7.0 : 1)
                .opacity(animate ? 0.3 : 1)
        }
        .onAppear { animate = true }
        .animation(.linear(duration: 0.7), value: animate)
    }
}

func processImage(image: UIImage, completion: @escaping (String?) -> Void) {
    let request = VNRecognizeTextRequest { request, error in
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            completion(nil)
            return
        }
        var scannedText = ""
        for observation in observations {
            guard let bestCandidate = observation.topCandidates(1).first else {
                continue
            }

            scannedText += bestCandidate.string
        }
        completion(scannedText)
    }
    
    let requests = [request]
    guard let img = image.cgImage else {
        completion(nil)
        return
    }
    let handler = VNImageRequestHandler(cgImage: img, options: [:])
    
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            try handler.perform(requests)
        } catch {
            completion(nil)
        }
    }
}

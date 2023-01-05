import SwiftUI

struct AllVideoView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: VideoModel
    @EnvironmentObject var pop: PopToRoot
    @State private var filter = false
    @Namespace private var animation
    @State var lower: [String] = ["iPhone 8", "iPhone 8 Plus", "iPhone SE"]
    @State private var id1 = "\(UUID())"
    @State private var id2 = "\(UUID())"
    @State private var showComments = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea([.bottom, .top])
            if !pop.Hide_Video {
                TabView(selection: $viewModel.selected){
                    ForEach(viewModel.VideosToShow){ video in
                        SingleVideoView(link: video.videoID).tag(video.videoID)
                    }
                    .rotationEffect(.init(degrees: -90))
                    .frame(width: widthOrHeight(width: true), height: widthOrHeight(width: false))
                }
                .offset(x: lower.contains(UIDevice.modelName) ? 9 : -10.5)
                .frame(width: widthOrHeight(width: false), height: widthOrHeight(width: true))
                .rotationEffect(.init(degrees: 90))
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            
            VStack(spacing: 35){
                if let i = viewModel.VideosToShow.firstIndex(where: { $0.videoID == viewModel.selected }){
                    VStack(spacing: 3){
                        CustomButton(systemImage: "hand.thumbsup.fill", status: viewModel.VideosToShow[i].liked, activeTint: .green, inActiveTint: .gray) {
                            id1 = "\(UUID())"
                            id2 = "\(UUID())"
                            if viewModel.VideosToShow[i].liked {
                                viewModel.VideosToShow[i].liked = false
                                viewModel.VideosToShow[i].likesCount -= 1
                            } else {
                                viewModel.VideosToShow[i].liked = true
                                viewModel.VideosToShow[i].likesCount += 1
                            }
                            if viewModel.VideosToShow[i].unliked {
                                viewModel.VideosToShow[i].unliked = false
                                viewModel.VideosToShow[i].dislikesCount += 1
                            }
                        }
                        StrokeTextLabel(text: formatNumber(viewModel.VideosToShow[i].likesCount))
                            .frame(width: 80, height: 30).id(id1)
                    }
                }
                
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showComments.toggle()
                } label: {
                    Image(systemName: "ellipsis.message.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(16)
                        .background {
                            Circle().fill(.gray.gradient.opacity(0.6))
                        }
                }
                
                CopyRotateView(link: String(viewModel.selected.dropLast(4)))
                
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    filter.toggle()
                } label: {
                    Image(systemName: "shuffle")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(16)
                        .background {
                            Circle().fill(.gray.gradient.opacity(0.6))
                        }
                }
            }
            .offset(x: widthOrHeight(width: true) * 0.4, y: lower.contains(UIDevice.modelName) ? widthOrHeight(width: false) * 0.06 : widthOrHeight(width: false) * 0.1)
            if let id = authViewModel.currentUser?.dev, id.contains("(DWK@)2))&DNWIDN:") {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    viewModel.deleteVid()
                } label: {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(16)
                        .background {
                            Circle().fill(.gray.gradient.opacity(0.6))
                        }
                }.offset(x: -widthOrHeight(width: true) * 0.34, y: -widthOrHeight(width: false) * 0.33)
            }
            Button {
                pop.Hide_Video = true
                withAnimation {
                    pop.Explore_or_Video = true
                }
            } label: {
                HStack(spacing: 1){
                    Text("Swipes").foregroundColor(.white).font(.title2).bold()
                    Image(systemName: "chevron.up").font(.body).bold().foregroundStyle(.white)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background {
                    Capsule().fill(.gray.opacity(0.4))
                }
            }.offset(x: -widthOrHeight(width: true) * 0.34, y: widthOrHeight(width: false) * 0.33)
        }
        .sheet(isPresented: $showComments, content: {
            if #available(iOS 16.4, *){
                VideoCommentView(videoID: viewModel.selected, canShowProfile: true)
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(40)
            } else {
                VideoCommentView(videoID: viewModel.selected, canShowProfile: true)
                    .presentationDetents([.medium, .large])
            }
        })
        .onAppear {
            viewModel.getMax()
        }
        .onChange(of: viewModel.selected, perform: { _ in
            id1 = "\(UUID())"
            id2 = "\(UUID())"
            if let index = viewModel.VideosToShow.lastIndex(where: { $0.videoID == viewModel.selected }){
                if (index + 4) > viewModel.VideosToShow.count {
                    viewModel.getBatch("")
                }
            }
        })
        .sheet(isPresented: $filter) {
            VStack {
                VStack(spacing: 0) {
                    HStack {
                        Text("Displaying").font(.title3).bold()
                        Spacer()
                    }.padding(.leading).padding(.top, 10)
                    ScrollView(.vertical) {
                        TagLayout(alignment: .center, spacing: 8) {
                            ForEach(viewModel.tags.filter { !viewModel.increase.contains($0) }, id: \.self) { tag in
                                if !viewModel.avoid.contains(tag){
                                    TagView(tag, .blue, "")
                                        .matchedGeometryEffect(id: tag, in: animation)
                                        .onTapGesture {
                                            withAnimation {
                                                viewModel.increase.insert(tag, at: 0)
                                            }
                                        }

                                }
                            }
                        }.padding(.vertical, 5).padding(.horizontal, 5)
                    }.scrollIndicators(.hidden).zIndex(0).padding(.top, 10)
                    HStack {
                        Text("Show More").font(.title3).bold()
                        Spacer()
                    }.padding(.leading)
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.increase, id: \.self) { tag in
                                TagView(tag, .orange, "checkmark")
                                    .matchedGeometryEffect(id: tag, in: animation)
                                    .onTapGesture {
                                        withAnimation {
                                            viewModel.increase.removeAll(where: { $0 == tag })
                                            viewModel.avoid.insert(tag, at: 0)
                                            if viewModel.avoid.count == 7 {
                                                viewModel.avoid.removeLast()
                                            }
                                        }
                                    }

                            }
                        }
                        .padding(.horizontal, 15)
                        .frame(height: 35)
                        .padding(.vertical, 15)
                    }.scrollIndicators(.hidden).zIndex(1)
                    HStack {
                        Text("Show Less").font(.title3).bold()
                        Spacer()
                    }.padding(.leading)
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.avoid, id: \.self) { tag in
                                TagView(tag, .pink.opacity(0.6), "xmark")
                                    .matchedGeometryEffect(id: tag, in: animation)
                                    .onTapGesture {
                                        withAnimation {
                                            viewModel.avoid.removeAll(where: { $0 == tag })
                                        }
                                    }

                            }
                        }
                        .padding(.horizontal, 15)
                        .frame(height: 35)
                        .padding(.vertical, 15)
                    }.scrollIndicators(.hidden).zIndex(2)
                }
                Spacer()
                Button {
                    withAnimation {
                        filter.toggle()
                    }
                } label: {
                    ZStack{
                        RoundedRectangle(cornerRadius: 10).fill(.blue.gradient)
                            .frame(height: 44)
                        Text("Done").font(.system(size: 20)).bold()
                    }.padding(.horizontal)
                }.padding(.bottom, 5)
            }
            .edgesIgnoringSafeArea(.horizontal)
            .presentationDetents([.height(400)])
        }
    }
    func formatNumber(_ number: Int) -> String {
        if number < 1000 {
            return "\(number)"
        } else {
            let thousands = Double(number) / 1000.0
            return String(format: "%.1fk", arguments: [thousands])
        }
    }
    @ViewBuilder
    func CustomButton(systemImage: String, status: Bool, activeTint: Color, inActiveTint: Color, onTap: @escaping () -> ()) -> some View {
        Button(action: onTap) {
            Image(systemName: systemImage)
                .font(.title2)
                .particleEffect360(
                    systemImage: systemImage,
                    font: .body,
                    status: status,
                    activeTint: activeTint,
                    inActiveTint: inActiveTint,
                    direction: systemImage == "hand.thumbsup.fill" ? true : false
                )
                .foregroundColor(status ? activeTint : inActiveTint)
                .padding(16)
                .background {
                    Circle()
                        .fill(status ? activeTint.opacity(0.6) : Color.blue.opacity(0.6))
                }
            
        }
    }
    func TagView(_ tag: String, _ color: Color, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Text(tag)
                .font(.callout)
                .fontWeight(.semibold)
            if !icon.isEmpty { Image(systemName: icon) }
        }
        .minimumScaleFactor(0.6)
        .frame(height: 35)
        .foregroundStyle(.white)
        .padding(.horizontal, 15)
        .background {
            Capsule()
                .fill(color.gradient)
        }
    }
}

struct StrokeTextLabel: UIViewRepresentable {
    let text: String
    
    func makeUIView(context: Context) -> UILabel {
        let attributedStringParagraphStyle = NSMutableParagraphStyle()
        attributedStringParagraphStyle.alignment = NSTextAlignment.center
        let attributedString = NSAttributedString(
            string: text,
            attributes:[
                NSAttributedString.Key.paragraphStyle: attributedStringParagraphStyle,
                NSAttributedString.Key.strokeWidth: -5.0,
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.strokeColor: UIColor.black,
                NSAttributedString.Key.font: UIFont(name:"Helvetica", size:20.0)!
            ]
        )

        let strokeLabel = UILabel(frame: CGRect.zero)
        strokeLabel.attributedText = attributedString
        strokeLabel.backgroundColor = UIColor.clear
        strokeLabel.sizeToFit()
        strokeLabel.center = CGPoint.init(x: 0.0, y: 0.0)
        return strokeLabel
    }

    func updateUIView(_ uiView: UILabel, context: Context) {}
}


struct Negative_Particle360: Identifiable {
    let id = UUID()
    var randomX = CGFloat.zero
    var randomY = CGFloat.zero
    var scale = CGFloat(1)
    var opacity = CGFloat(1)

    init() {
        reset()
    }

    mutating func reset() {
        randomX = CGFloat.zero
        randomY = CGFloat.zero
        while ((randomX * randomX) + (randomY * randomY)).squareRoot() < 75 {
            randomX = CGFloat.random(in: -100...100)
            randomY = CGFloat.random(in: -100...100)
        }
        scale = 1
        opacity = 1
    }
}

extension View {
    @ViewBuilder
    func particleEffect360(systemImage: String, font: Font, status: Bool, activeTint: Color, inActiveTint: Color, direction: Bool) -> some View {
        self
            .modifier(
                ParticleModifier360(systemImage: systemImage, font: font, status: status, activeTint: activeTint, inActiveTint: inActiveTint, direction: direction)
            )
        
    }
}

struct Particle: Identifiable {
    var id: UUID = .init()
    var randomX: CGFloat = 0
    var randomY: CGFloat = 0
    var scale: CGFloat = 1
    var opacity: CGFloat = 1
    mutating func reset() {
        randomX = 0
        randomY = 0
        scale = 1
        opacity = 1
    }
}

fileprivate struct ParticleModifier360: ViewModifier {
    var systemImage: String
    var font: Font
    var status: Bool
    var activeTint: Color
    var inActiveTint: Color
    var direction: Bool
    @State private var particles: [Particle] = []
    @State private var negative_particles: [Negative_Particle360] = []
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                ZStack {
                    if direction {
                        ForEach(particles) { particle in
                            Image(systemName: systemImage)
                                .font(font)
                                .foregroundColor(status ? activeTint : inActiveTint)
                                .scaleEffect(particle.scale)
                                .offset(x: particle.randomX, y: particle.randomY)
                                .opacity(particle.opacity)
                                .opacity(status ? 1 : 0)
                                .animation(.none, value: status)
                        }
                    } else {
                        ForEach(negative_particles) { particle in
                            Image(systemName: systemImage)
                                .font(font)
                                .foregroundColor(status ? activeTint : inActiveTint)
                                .scaleEffect(particle.scale)
                                .offset(x: particle.randomX, y: particle.randomY)
                                .opacity(particle.opacity)
                                .opacity(status ? 1 : 0)
                                .animation(.none, value: status)
                        }
                    }
                }
                .onAppear {
                    if direction {
                        if particles.isEmpty {
                            for _ in 1...15 {
                                let particle = Particle()
                                particles.append(particle)
                            }
                        }
                    } else {
                        if negative_particles.isEmpty {
                            for _ in 1...15 {
                                let particle = Negative_Particle360()
                                negative_particles.append(particle)
                            }
                        }
                    }
                }
                .onChange(of: status) { newValue in
                    if !newValue {
                        if direction {
                            for index in particles.indices {
                                particles[index].reset()
                            }
                        } else {
                            for index in negative_particles.indices {
                                negative_particles[index].reset()
                            }
                        }
                    } else {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if direction {
                            for index in particles.indices {
                                let total: CGFloat = CGFloat(particles.count)
                                let progress: CGFloat = CGFloat(index) / total
                                
                                let angle: CGFloat = progress * 2 * .pi
                                
                                let radius: CGFloat = 75
                                let centerX: CGFloat = 0
                                let centerY: CGFloat = 0
                                
                                let randomX: CGFloat = radius * cos(angle) + centerX
                                let randomY: CGFloat = radius * sin(angle) + centerY
                                let randomScale: CGFloat = .random(in: 0.35...1)
                                
                                withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.7)) {
                                    let extraRandomX: CGFloat = .random(in: -10...10)
                                    let extraRandomY: CGFloat = .random(in: 0...40)
                                    
                                    particles[index].randomX = randomX + extraRandomX
                                    particles[index].randomY = randomY + extraRandomY
                                }
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    particles[index].scale = randomScale
                                }
                                withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.7)
                                    .delay(0.25 + (Double(index) * 0.005))) {
                                        particles[index].scale = 0.001
                                }
                            }
                        } else {
                            for index in negative_particles.indices {
                                let randomScale: CGFloat = .random(in: 0.8...1)
                                let targetX: CGFloat = .random(in: -5...5)
                                let targetY: CGFloat = .random(in: -5...5)
                                withAnimation(.easeIn(duration: 0.3)) {
                                    negative_particles[index].randomX = targetX
                                    negative_particles[index].randomY = targetY
                                    negative_particles[index].scale = randomScale
                                }
                                withAnimation(.easeIn(duration: 0.5).delay(0.2)) {
                                        negative_particles[index].scale = 0.001
                                }
                            }
                        }
                    }
                }
            }
        
    }
}

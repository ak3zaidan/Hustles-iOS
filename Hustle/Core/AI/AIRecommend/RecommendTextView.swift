import SwiftUI

struct AIRec: Identifiable {
    var id = UUID().uuidString
    var text: String
}

struct AIText: Identifiable {
    var id = UUID().uuidString
    var oldText: String
    var options: [AIRec]
}

struct RecommendTextView: View {
    @EnvironmentObject var vm: ViewModel
    @Environment(\.dismiss) var dismiss
    @State var error = false
    @State var currentIndex: Int = 0
    @State var moveToIndex: Int = 0
    @State var generating = false
    @State var text = ""
    @Binding var oldText: String
    let allModifications: [(String, String)] = [
        ("Fix", "hammer"),
        ("Rephrase", "pencil"),
        ("Make funnier", "face.smiling.inverse"),
        ("Shorten", "scissors"),
        ("Fix Grammar", "slider.vertical.3"),
        ("Ellaborate", "plus")
    ]
    
    var body: some View {
        VStack {
            header().padding(.top, 20)
            Spacer()
            if generating {
                LottieView(loopMode: .loop, name: "aiLoad")
                    .scaleEffect(0.8)
                    .frame(width: 100, height: 100)
                    .transition(.scale.combined(with: .opacity))
            } else {
                centerText()
                    .transition(.scale.combined(with: .opacity))
            }
            Spacer()
            BottomOptions()
        }
        .onAppear(perform: {
            if let index = vm.textOptions.firstIndex(where: { $0.oldText.lowercased() == oldText.lowercased() }) {
                self.vm.currentPosition = index
            }
        })
        .onDisappear(perform: {
            self.vm.currentPosition = 10000
        })
        .presentationDetents([.fraction(0.99)])
        .presentationCornerRadius(20)
        .presentationDragIndicator(.visible)
        .background {
            ZStack {
                LinearGradient(colors: [Color(red: 25 / 255, green: 176 / 255, blue: 255 / 255), .blue, .blue, .purple], startPoint: .bottomLeading, endPoint: .topTrailing)
                TransparentBlurView(removeAllFilters: true)
                    .blur(radius: 14, opaque: true)
                    .background(.black).opacity(0.45)
            }.ignoresSafeArea()
        }
        .overlay {
            if error {
                VStack {
                    HStack(spacing: 10){
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("An Error Occured").font(.headline).bold()
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)){
                            error = false
                        }
                    }
                    .padding(.horizontal, 50)
                    Spacer()
                }.padding(.top, 60).transition(.move(edge: .top))
            }
        }
    }
    func getValid() -> [AIRec] {
        if vm.currentPosition < vm.textOptions.count {
            return vm.textOptions[vm.currentPosition].options
        }
        return []
    }
    @ViewBuilder
    func centerText() -> some View {
        VStack {
            let all: [AIRec] = [AIRec(text: oldText)] + getValid()
            
            if let first = all.first, all.count == 1 {
                GeometryReader { proxy in
                    let size = proxy.size
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(first.text)
                                .padding(20)
                                .background((Color(red: 25 / 255, green: 176 / 255, blue: 255 / 255)))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            Spacer()
                        }
                        .frame(width: size.width)
                        Spacer()
                    }
                }
            } else {
                SnapCarousel(index: $currentIndex, moveToIndex: $moveToIndex, items: all) { post in
                    GeometryReader { proxy in
                        let size = proxy.size
                        let index = all.firstIndex(where: { $0.id == post.id }) ?? 0
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                if post.text.count > 200 && post.text != oldText {
                                    TextField("", text: .constant(post.text), axis: .vertical)
                                        .lineLimit(10)
                                        .padding(20)
                                        .background((Color(red: 25 / 255, green: 176 / 255, blue: 255 / 255)))
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                } else {
                                    Text(post.text)
                                        .padding(20)
                                        .background((Color(red: 25 / 255, green: 176 / 255, blue: 255 / 255)))
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                }
                                Spacer()
                            }
                            .frame(width: size.width)
                            .opacity(index == currentIndex ? 1.0 : 0.5)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder
    func BottomOptions() -> some View {
        VStack(spacing: 10){
            ScrollView(.horizontal) {
                LazyHStack(spacing: 10){
                    Color.gray.opacity(0.001).frame(width: 7.5)
                    ForEach(allModifications, id: \.0) { element in
                        Button {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)){
                                text = element.0
                                generating = true
                            }
                            let command = element.0 + ": "
                            vm.sendNormalMessage(command: command, text: oldText) { bool in
                                withAnimation(.easeInOut(duration: 0.2)){
                                    self.generating = false
                                }
                                if bool {
                                    if vm.currentPosition < vm.textOptions.count {
                                        moveToIndex = vm.textOptions[vm.currentPosition].options.count
                                        currentIndex = moveToIndex
                                    }
                                } else {
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        self.error = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                                        withAnimation(.easeInOut(duration: 0.15)){
                                            self.error = false
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 2){
                                Image(systemName: element.1)
                                Text(element.0).bold()
                            }
                            .foregroundStyle(.white).font(.subheadline)
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .background(content: {
                                TransparentBlurView(removeAllFilters: true)
                                    .blur(radius: 14, opaque: true)
                                    .background(.white).opacity(0.18)
                            })
                            .clipShape(Capsule())
                        }
                    }
                    Color.gray.opacity(0.001).frame(width: 7.5)
                }
            }.scrollIndicators(.hidden).frame(height: 45)
            TextField("", text: $text)
                .disabled(generating)
                .foregroundStyle(.white)
                .padding(.leading).padding(.trailing, 60).tint(.green)
                .frame(height: 40)
                .background {
                    ZStack {
                        TransparentBlurView(removeAllFilters: true)
                            .blur(radius: 14, opaque: true)
                            .background(.white).opacity(0.18)
                        if text.isEmpty {
                            HStack {
                                Text("Try 'talk like an attorney'")
                                    .foregroundStyle(.white)
                                    .fontWeight(.light)
                                    .opacity(0.7)
                                    .padding(.leading).padding(.leading, 1)
                                Spacer()
                            }
                        }
                    }
                }
                .overlay(content: {
                    if !text.isEmpty && !generating {
                        HStack {
                            Spacer()
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.2)){
                                    generating = true
                                }
                                let command = text + ": "
                                vm.sendNormalMessage(command: command, text: oldText) { bool in
                                    withAnimation(.easeInOut(duration: 0.2)){
                                        self.generating = false
                                    }
                                    if bool {
                                        if vm.currentPosition < vm.textOptions.count {
                                            moveToIndex = vm.textOptions[vm.currentPosition].options.count
                                            currentIndex = moveToIndex
                                        }
                                    } else {
                                        withAnimation(.easeInOut(duration: 0.2)){
                                            self.error = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                                            withAnimation(.easeInOut(duration: 0.15)){
                                                self.error = false
                                            }
                                        }
                                    }
                                }
                            }, label: {
                                Image(systemName: "paperplane.fill")
                                    .fontWeight(.light)
                                    .font(.headline).rotationEffect(.degrees(45.0))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14).padding(.vertical, 5)
                                    .background(Color(red: 25 / 255, green: 176 / 255, blue: 255 / 255))
                                    .clipShape(Capsule())
                            })
                        }.padding(.trailing, 8)
                    }
                })
                .clipShape(Capsule())
                .padding(.horizontal, 15).padding(.bottom, 15)
        }
    }
    @ViewBuilder
    func header() -> some View {
        ZStack {
            HStack {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                }, label: {
                    ZStack {
                        Rectangle().foregroundStyle(.gray).opacity(0.001)
                            .frame(width: 50, height: 25)
                        Text("Cancel")
                            .fontWeight(.light)
                            .font(.headline).foregroundStyle(.white)
                    }
                })
                Spacer()
            }
            HStack(spacing: 4){
                Spacer()
                LottieView(loopMode: .loop, name: "finite")
                    .scaleEffect(0.045)
                    .frame(width: 22, height: 10)
                Text("Hustles AI")
                    .bold()
                    .font(.headline).foregroundStyle(.white)
                Spacer()
            }.scaleEffect(1.1)
            HStack {
                Spacer()
                Button(action: {
                    let all: [AIRec] = [AIRec(text: oldText)] + getValid()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if currentIndex < all.count {
                        oldText = all[currentIndex].text
                    }
                    dismiss()
                }, label: {
                    ZStack {
                        Rectangle().foregroundStyle(.gray).opacity(0.001)
                            .frame(width: 50, height: 25)
                        Text("Apply")
                            .font(.headline).foregroundStyle(.white)
                    }.opacity(currentIndex == 0 ? 0.6 : 1.0)
                }).disabled(currentIndex == 0)
            }
        }.padding(.horizontal, 15)
    }
}

struct SnapCarousel<Content: View, T: Identifiable>: View {
    var content: (T) -> Content
    var list: [T]
    var spacing: CGFloat
    var trailingSpace: CGFloat
    @Binding var index: Int
    @Binding var moveToIndex: Int
    
    init(spacing: CGFloat = 15, trailingSpace: CGFloat = 150, index: Binding<Int>, moveToIndex: Binding<Int>, items: [T], @ViewBuilder content: @escaping (T)->Content){
        
        self.list = items
        self.spacing = spacing
        self.trailingSpace = trailingSpace
        self._index = index
        self._moveToIndex = moveToIndex
        self.content = content
    }

    @GestureState var offset: CGFloat = 0
    @State var currentIndex: Int = 0
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width - ( trailingSpace - spacing )
            let adjustMentWidth = (trailingSpace / 2) - spacing
            
            HStack(spacing: spacing) {
                ForEach(list) { item in
                    content(item)
                        .frame(width: proxy.size.width - trailingSpace)
                }
            }
            .padding(.horizontal, spacing)
            .offset(x: (CGFloat(currentIndex) * -width) + ( currentIndex != 0 ? adjustMentWidth : 0 ) + offset)
            .gesture (
                DragGesture()
                    .updating($offset, body: { value, out, _ in
                        out = value.translation.width
                    })
                    .onEnded({ value in
                        let offsetX = value.translation.width
                        let progress = -offsetX / width
                        let roundIndex = progress.rounded()
                        currentIndex = max(min(currentIndex + Int(roundIndex), list.count - 1), 0)
                        currentIndex = index
                    })
                    .onChanged({ value in
                        let offsetX = value.translation.width
                        let progress = -offsetX / width
                        let roundIndex = progress.rounded()
                        index = max(min(currentIndex + Int(roundIndex), list.count - 1), 0)
                    })
            )
            .onChange(of: moveToIndex) { _, _ in
                withAnimation(.easeInOut(duration: 0.15)){
                    currentIndex = moveToIndex
                }
            }
        }
        .animation(.easeInOut, value: offset == 0)
    }
}

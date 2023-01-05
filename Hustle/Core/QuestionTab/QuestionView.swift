import SwiftUI
import MarqueeText

struct QuestionView: View {
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var viewModel: QuestionModel
    @EnvironmentObject var auth: AuthViewModel
    @State private var showNewQuestionView = false
    @Environment(\.colorScheme) var colorScheme
    @State private var selection = 0
    static let lowGrey = Color("lowgrey")
    let generator = UINotificationFeedbackGenerator()
    let spaceName = "scroll"
    @State var scrollViewSize: CGSize = .zero
    @State var wholeSize: CGSize = .zero
    @State private var offset: Double = 0
    @State private var canROne = true
    @State private var canRTwo = true
    @State private var canOne = true
    @State private var canTwo = true
    @State private var viewShowing = false
    @State private var showAI = false
    
    var body: some View {
        ZStack {
            ZStack(alignment: .bottomTrailing){
                ScrollView(.init()){
                    TabView(selection: $selection) {
                        ScrollViewReader { proxy in
                            ChildSizeReader(size: $wholeSize) {
                                ScrollView {
                                    ChildSizeReader(size: $scrollViewSize) {
                                        LazyVStack {
                                            Color.clear.frame(height: 105).id("scrolltop")
                                            if viewModel.new.isEmpty {
                                                VStack {
                                                    ForEach(0..<7){ i in
                                                        LoadingFeed(lesson: "")
                                                    }
                                                }.shimmering()
                                            } else {
                                                ForEach(viewModel.new) { question in
                                                    if question.image1 == nil {
                                                        NavigationLink {
                                                            QuestionSingleView(disableUser: false, question: question, isSheet: false)
                                                        } label: {
                                                            QuestionRowView(question: question, bottomPad: false)
                                                        }
                                                    } else {
                                                        NavigationLink {
                                                            ImageQuestionView(question: question, disableUser: false, shouldShowTab: true)
                                                                .onAppear {
                                                                    withAnimation(.spring()){
                                                                        self.popRoot.hideTabBar = true
                                                                    }
                                                                }
                                                                .onDisappear {
                                                                    withAnimation(.spring()){
                                                                        self.popRoot.hideTabBar = false
                                                                    }
                                                                }
                                                        } label: {
                                                            ImageQuestionRow(question: question, bottomPad: false)
                                                        }
                                                    }
                                                }
                                            }
                                            Color.clear.frame(height: 135)
                                        }
                                        .background(GeometryReader {
                                            Color.clear.preference(key: ViewOffsetKey.self,
                                                                   value: -$0.frame(in: .named("scroll")).origin.y)
                                        })
                                        .onPreferenceChange(ViewOffsetKey.self) { value in
                                            offset = value
                                            if offset > 100 {
                                                if value > (scrollViewSize.height - wholeSize.height) - 300{
                                                    if canOne{
                                                        canOne = false
                                                        viewModel.getNew()
                                                        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                                                            canOne = true
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .refreshable { }
                                .scrollIndicators(.hidden)
                                .onChange(of: popRoot.tap) { _, _ in
                                    if popRoot.tap == 4 && selection == 0 && viewShowing {
                                        withAnimation { proxy.scrollTo("scrolltop", anchor: .bottom) }
                                        popRoot.tap = 0
                                    }
                                }
                            }
                            .coordinateSpace(name: spaceName)
                        }.tag(0)
                        ScrollViewReader { proxy in
                            ChildSizeReader(size: $wholeSize) {
                                ScrollView {
                                    ChildSizeReader(size: $scrollViewSize) {
                                        LazyVStack {
                                            Color.clear.frame(height: 105).id("scrolltop")
                                            if viewModel.top.isEmpty {
                                                VStack {
                                                    ForEach(0..<7){ i in
                                                        LoadingFeed(lesson: "")
                                                    }
                                                }.shimmering()
                                            } else {
                                                ForEach(viewModel.top) { question in
                                                    if question.image1 == nil {
                                                        NavigationLink {
                                                            QuestionSingleView(disableUser: false, question: question, isSheet: false)
                                                        } label: {
                                                            QuestionRowView(question: question, bottomPad: false)
                                                        }
                                                    } else {
                                                        NavigationLink {
                                                            ImageQuestionView(question: question, disableUser: false, shouldShowTab: true)
                                                                .onAppear {
                                                                    withAnimation {
                                                                        self.popRoot.hideTabBar = true
                                                                    }
                                                                }
                                                                .onDisappear {
                                                                    withAnimation {
                                                                        self.popRoot.hideTabBar = false
                                                                    }
                                                                }
                                                        } label: {
                                                            ImageQuestionRow(question: question, bottomPad: false)
                                                        }
                                                    }
                                                }
                                            }
                                            Color.clear.frame(height: 135)
                                        }
                                        .background(GeometryReader {
                                            Color.clear.preference(key: ViewOffsetKey.self,
                                                                   value: -$0.frame(in: .named("scroll")).origin.y)
                                        })
                                        .onPreferenceChange(ViewOffsetKey.self) { value in
                                            offset = value
                                            if offset > 200 {
                                                if value > (scrollViewSize.height - wholeSize.height) - 300{
                                                    if canTwo{
                                                        canTwo = false
                                                        viewModel.getTop()
                                                        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                                                            canTwo = true
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .refreshable { }
                                .scrollIndicators(.hidden)
                                .onChange(of: popRoot.tap) { _, _ in
                                    if popRoot.tap == 4 && selection == 1 && viewShowing {
                                        withAnimation { proxy.scrollTo("scrolltop", anchor: .bottom) }
                                        popRoot.tap = 0
                                    }
                                }
                            }
                            .coordinateSpace(name: spaceName)
                        }.tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }.ignoresSafeArea()
                HStack {
                    Spacer()
                    Button {
                        showNewQuestionView.toggle()
                    } label: {
                        Image("logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 57)
                            .padding()
                    }
                    .shadow(color: .gray.opacity(0.6), radius: 10, x: 0, y: 0)
                    .frame(width: 75, height: 35)
                    .background(Color(.systemOrange).opacity(0.9))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    Spacer()
                }
                .padding(.bottom, 140)
                .fullScreenCover(isPresented: $showNewQuestionView){
                    UploadQuestion()
                }
                VStack {
                    HStack {
                        LottieView(loopMode: .loop, name: "finite")
                            .scaleEffect(0.055)
                            .frame(width: 10, height: 10)
                        Text("AI").font(.subheadline).padding(.leading, 15)
                        MarqueeText (
                            text: "your virtual assistant, ask me anything.",
                            font: UIFont.preferredFont(forTextStyle: .subheadline),
                            leftFade: 10,
                            rightFade: 16,
                            startDelay: 3
                        ).frame(width: 150).padding(.leading, 5)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 44)
                    .background {
                        TransparentBlurView(removeAllFilters: true)
                            .blur(radius: 14, opaque: true)
                            .background(colorScheme == .dark ? Color(UIColor.lightGray).opacity(0.55) : Color(UIColor.darkGray).opacity(0.5))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                    .onTapGesture {
                        showAI = true
                    }
                    Spacer()
                }.transition(.move(edge: .top).combined(with: .opacity))
                if (offset <= -75) {
                    VStack {
                        HStack {
                            Spacer()
                            Loader(flip: true)
                            Spacer()
                        }.padding(.top, 55)
                        Spacer()
                    }
                }
            }
            .onChange(of: offset) { _, _ in
                if offset <= -80 {
                    if (selection == 0) && canROne {
                       viewModel.refresh()
                       generator.notificationOccurred(.success)
                       canROne = false
                       Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { _ in
                           canROne = true
                       }
                    } else if canRTwo {
                        generator.notificationOccurred(.success)
                        canRTwo = false
                        Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { _ in
                            canRTwo = true
                        }
                    }
                }
            }
            VStack {
                Spacer()
                VStack {
                    HStack(spacing: 50){
                        HStack(alignment: .center, spacing: 0) {
                            Button {
                                withAnimation(.easeInOut){
                                    selection = 0
                                }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } label: {
                                Text("New").foregroundStyle(colorScheme == .dark ? .black : .white).bold().frame(width: 80, height: 25)
                            }
                            .background((selection == 0) ? colorScheme == .dark ? QuestionView.lowGrey : .gray : colorScheme == .dark ? .gray : QuestionView.lowGrey)
                            Button {
                                withAnimation(.easeInOut){
                                    selection = 1
                                }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                if viewModel.top.isEmpty {
                                    viewModel.getTop()
                                }
                            } label: {
                                Text("Top").foregroundStyle(colorScheme == .dark ? .black : .white).bold().frame(width: 80, height: 25)
                            }
                            .background((selection == 1) ? colorScheme == .dark ? QuestionView.lowGrey : .gray : colorScheme == .dark ? .gray : QuestionView.lowGrey)
                            Button {
                                showAI = true
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } label: {
                                HStack(spacing: 2){
                                    Text("AI")
                                    Image(systemName: "bolt.fill")
                                }
                                .scaleEffect(1.05)
                                .gradientForeground(colors: colorScheme == .dark ? [.yellow, .green] : [.purple, .blue]).bold().frame(width: 80, height: 25)
                            }.background(colorScheme == .dark ? .gray : QuestionView.lowGrey)
                        }
                        .mask {
                            RoundedRectangle(cornerRadius: 5)
                        }
                    }.padding(.top, 5)
                    Spacer()
                }
                .frame(width: widthOrHeight(width: true), height: 90)
                .background {
                    TransparentBlurView(removeAllFilters: true)
                        .blur(radius: 7, opaque: true)
                        .background(colorScheme == .dark ? .black.opacity(0.6) : .white.opacity(0.8))
                }
                .padding(.bottom, 10)
            }
        }
        .fullScreenCover(isPresented: $showAI, content: {
            BaseAIView()
        })
        .onDisappear { viewShowing = false }
        .onAppear {
            viewShowing = true
            if viewModel.new.isEmpty {
                viewModel.getNew()
            }
        }
        .onChange(of: selection) { _, _ in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if selection == 1 && viewModel.top.isEmpty {
                viewModel.getTop()
            }
        }
    }
}

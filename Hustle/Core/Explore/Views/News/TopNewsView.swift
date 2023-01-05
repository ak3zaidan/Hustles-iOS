import SwiftUI
import Kingfisher

struct TopNewsView: View, KeyboardReadable {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var viewModel: ExploreViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var showBackground = false
    @State private var newOrTop = 0
    @State var showForward = false
    @State var sendString: String = ""
    @State var wholeSize: CGSize = .zero
    @State var scrollViewSize: CGSize = .zero
    @State var selectedOpinion: String?
    @State private var canRefreshNew = true
    @State private var howLongToShow = true
    @State private var replyNews: String = ""
    @State private var replyNewsError: Bool = false
    @FocusState var isEditing
    @State private var canTwo = true
    @State private var canThree = true
    @State private var showAnonymous = false
    @State private var includeUsername: Bool? = nil
    @State private var tag = ""
    @State private var keyBoardVisible = false
    @State private var target = ""
    @State var showAI = false
    @State var offset: CGFloat = 0.0
    
    let animation: Namespace.ID
    let newsMid: String
    let animate: Bool
    let news: News
    
    var body: some View {
        ZStack {
            if showBackground || !animate {
                if colorScheme == .dark {
                    Color.black.ignoresSafeArea().transition(.opacity)
                } else {
                    Color.white.ignoresSafeArea().transition(.opacity)
                }
            }
            VStack {
                Link(destination: URL(string: news.link)!) {
                    NewsRowView(news: news, isRow: false)
                        .background(content: {
                            ZStack {
                                if colorScheme == .dark {
                                    RoundedRectangle(cornerRadius: 10).foregroundColor(.black)
                                    RoundedRectangle(cornerRadius: 10).foregroundColor(.gray).opacity(0.35)
                                } else {
                                    RoundedRectangle(cornerRadius: 10).foregroundColor(.white)
                                    RoundedRectangle(cornerRadius: 10).foregroundColor(.gray).opacity(0.2)
                                }
                            }
                        })
                        .matchedGeometryEffect(id: newsMid, in: animation).padding(.horizontal, 10)
                        .offset(y: offset * 0.3)
                        .gesture(DragGesture()
                            .onChanged({ value in
                                self.offset = value.translation.height
                            })
                            .onEnded({ value in
                                withAnimation(.easeInOut(duration: 0.2)){
                                    self.offset = 0.0
                                }
                                if value.translation.height > 10 {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    viewModel.currentNews = -1
                                    if animate {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            popRoot.newsMid = ""
                                        }
                                        withAnimation(.easeInOut(duration: 0.1)){
                                            showBackground = false
                                        }
                                        withAnimation(.easeInOut(duration: 0.2)){
                                            popRoot.isNewsExpanded = false
                                        }
                                    } else {
                                        dismiss()
                                        withAnimation {
                                            self.popRoot.hideTabBar = false
                                        }
                                    }
                                }
                            })
                        )
                }
                if showBackground || !animate {
                    topBar().padding(.top, 4)
                    
                    mainContent()
                    
                    Spacer()
                    
                    if keyBoardVisible && replyNews.contains("@") && tag.isEmpty {
                        TaggedUserView(text: $replyNews, target: $target, commentID: nil, newsID: news.id, newsRepID: nil, questionID: nil, groupID: nil, selectedtag: $tag)
                    }
                    
                    if animate {
                        textBar()
                            .padding(.horizontal).padding(.bottom, keyBoardVisible ? 10 : bottom_Inset())
                            .KeyboardAwarePadding()
                    } else {
                        textBar().padding(.bottom, keyBoardVisible ? 10 : 0)
                    }
                } else {
                    Spacer()
                }
            }
            if let username = authViewModel.currentUser?.username, showAnonymous {
                VStack {
                    UnknownView(show: $showAnonymous, caption: $replyNews, tag: $tag, username: username, newsName: news.title)
                }.transition(.move(edge: .top))
            }
        }
        .onAppear(perform: {
            withAnimation(.easeInOut(duration: 0.4)){
                showBackground = true
            }
            ExploreService().addNewsView(id: news.id ?? "")
            viewModel.startNewsGroup(newsID: news.id ?? "", blocked: authViewModel.currentUser?.blockedUsers ?? [], newOrTop: newOrTop)
        })
        .onChange(of: tag) { _, _ in
            if !tag.isEmpty {
                if let range = replyNews.range(of: "@") {
                    let final = replyNews.replacingCharacters(in: range, with: "@\(tag) ")
                    replyNews = removeSecondOccurrence(of: target, in: final)
                    target = ""
                }
            }
        }
        .alert("Only 1 opinion per category is allowed", isPresented: $viewModel.showOnlyOne) {
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: newOrTop) { _, _ in
            viewModel.startNewsGroup(newsID: news.id ?? "", blocked: authViewModel.currentUser?.blockedUsers ?? [], newOrTop: newOrTop)
        }
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendString)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
        })
        .navigationBarBackButtonHidden(true)
        .onReceive(keyboardPublisher) { newIsKeyboardVisible in
            keyBoardVisible = newIsKeyboardVisible
            if !newIsKeyboardVisible && !showAnonymous {
                selectedOpinion = nil
            }
        }
    }
    @ViewBuilder
    func textBar() -> some View {
        HStack(alignment: .center){
            if showAI {
                SimpleAIView(text: $replyNews).transition(.scale.combined(with: .opacity))
            } else {
                ZStack {
                    personView(size: 35)
                    if let image = authViewModel.currentUser?.profileImageUrl {
                        KFImage(URL(string: image))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 35, height: 35)
                            .clipShape(Circle())
                            .shadow(color: .gray, radius: 1)
                    }
                }.transition(.scale.combined(with: .opacity))
            }
            
            NewsMessageField()
        }
    }
    @ViewBuilder
    func mainContent() -> some View {
        TabView(selection: $newOrTop) {
            ChildSizeReader(size: $wholeSize) {
                ScrollView {
                    ChildSizeReader(size: $scrollViewSize) {
                        LazyVStack(spacing: 6){
                            if !howLongToShow {
                                HStack {
                                    Spacer()
                                    Loader(flip: true)
                                    Spacer()
                                }
                            }
                            if let context = news.context, !context.isEmpty {
                                contextView(context: context).padding(.horizontal, 10).padding(.bottom, 10)
                            }
                            if viewModel.currentNews >= 0 {
                                if viewModel.NewsGroups[viewModel.currentNews].1.isEmpty && newOrTop == 0 {
                                    ProgressView()
                                }
                                ForEach(viewModel.NewsGroups[viewModel.currentNews].1){ reply in
                                    Button {
                                    } label: {
                                        NewsReplyView(newsID: news.id ?? "", reply: reply, binded_string: $selectedOpinion, noNavStack: animate)
                                    }
                                }
                            } else {
                                VStack {
                                    ForEach(0..<4) { _ in
                                        HStack {
                                            Spacer()
                                            LoadingNews().padding(.horizontal, 10)
                                            Spacer()
                                        }
                                    }
                                }.shimmering()
                            }
                        }
                        .onChange(of: selectedOpinion, { _, _ in
                            replyNews = ""
                            if selectedOpinion != nil {
                                isEditing = true
                            }
                        })
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewOffsetKey.self,
                                                   value: -$0.frame(in: .named("scrollXX")).origin.y)
                        })
                        .onPreferenceChange(ViewOffsetKey.self) { value in
                            if viewModel.currentNews >= 0 {
                                if value < -70 && canRefreshNew {
                                    withAnimation {
                                        howLongToShow = false
                                    }
                                    canRefreshNew = false
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    viewModel.getNewsRepsNew(blocked: authViewModel.currentUser?.blockedUsers ?? [])
                                    Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                                        withAnimation {
                                            howLongToShow = true
                                        }
                                    }
                                    Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
                                        canRefreshNew = true
                                    }
                                }
                                if value > (scrollViewSize.height - wholeSize.height) - 350 {
                                    if value > 200 && canTwo {
                                        canTwo = false
                                        viewModel.getNewsReps(blocked: authViewModel.currentUser?.blockedUsers ?? [], newOrTop: newOrTop)
                                        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                                            canTwo = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top, 5).scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
            }.coordinateSpace(name: "scrollXX").tag(0)
            ChildSizeReader(size: $wholeSize) {
                ScrollView {
                    ChildSizeReader(size: $scrollViewSize) {
                        LazyVStack(spacing: 6){
                            if viewModel.currentNews >= 0 {
                                if viewModel.NewsGroups[viewModel.currentNews].2.isEmpty && newOrTop == 1 {
                                    ProgressView()
                                }
                                if let context = news.context, !context.isEmpty {
                                    contextView(context: context).padding(.horizontal, 10).padding(.bottom, 10)
                                }
                                ForEach(viewModel.NewsGroups[viewModel.currentNews].2){ reply in
                                    Button {
                                        
                                    } label: {
                                        NewsReplyView(newsID: news.id ?? "", reply: reply, binded_string: $selectedOpinion, noNavStack: animate)
                                    }
                                }
                            } else {
                                if let context = news.context, !context.isEmpty {
                                    contextView(context: context).padding(.horizontal, 10).padding(.bottom, 10)
                                }
                                VStack {
                                    ForEach(0..<4) { _ in
                                        HStack {
                                            Spacer()
                                            LoadingNews().padding(.horizontal, 10)
                                            Spacer()
                                        }
                                    }
                                }.shimmering()
                            }
                        }
                        .onChange(of: selectedOpinion, { _, _ in
                            replyNews = ""
                            if selectedOpinion != nil {
                                isEditing = true
                            }
                        })
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewOffsetKey.self,
                                                   value: -$0.frame(in: .named("scrollXX")).origin.y)
                        })
                        .onPreferenceChange(ViewOffsetKey.self) { value in
                            if viewModel.currentNews >= 0 {
                                if value > (scrollViewSize.height - wholeSize.height) - 350 {
                                    if value > 200 && canThree {
                                        canThree = false
                                        viewModel.getNewsReps(blocked: authViewModel.currentUser?.blockedUsers ?? [], newOrTop: newOrTop)
                                        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                                            canThree = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top, 5).scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
            }.coordinateSpace(name: "scrollXX").tag(1)
        }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
    @ViewBuilder
    func contextView(context: String) -> some View {
        VStack(spacing: 10){
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(.blue).font(.body)
                Text("Hustles Context").fontWeight(.heavy).font(.body)
                Spacer()
            }
            Text(context)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
        }
        .padding(10)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    @ViewBuilder
    func topBar() -> some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 30).frame(height: 30)
                    .foregroundColor(.blue).opacity(0.45)
                HStack {
                    Text(news.tags).font(.system(size: 14)).bold()
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation {
                            if newOrTop == 0 {
                                newOrTop = 1
                            } else {
                                newOrTop = 0
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 30).frame(width: 60, height: 30)
                                .foregroundColor(.gray)
                            if newOrTop == 0 {
                                Text("New").font(.system(size: 14)).bold()
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                            } else {
                                Text("Top").font(.system(size: 14)).bold()
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                            }
                        }
                    }
                    Spacer()
                    (Text("\(formatNumber(number: Double(news.views ?? 0)))") + Text(Image(systemName: "chart.bar.fill")))
                        .font(.system(size: 14)).bold()
                }.padding(.horizontal, 5)
            }.padding(.leading, 9).padding(.trailing, 4)
            Spacer()
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                sendString = "https://hustle.page/news/\(news.id ?? "")/"
                showForward = true
            }, label: {
                ZStack {
                    Circle().foregroundStyle(colorScheme == .dark ? Color(UIColor.darkGray) : Color(UIColor.lightGray))
                    Image(systemName: "paperplane.fill").font(.subheadline)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }.frame(width: 30, height: 30)
            })
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                viewModel.currentNews = -1
                if animate {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        popRoot.newsMid = ""
                    }
                    withAnimation(.easeInOut(duration: 0.1)){
                        showBackground = false
                    }
                    withAnimation(.easeInOut(duration: 0.2)){
                        popRoot.isNewsExpanded = false
                    }
                } else {
                    dismiss()
                    withAnimation {
                        self.popRoot.hideTabBar = false
                    }
                }
            } label: {
                ZStack {
                    Circle().foregroundStyle(colorScheme == .dark ? Color(UIColor.darkGray) : Color(UIColor.lightGray))
                    Image(systemName: "xmark").font(.subheadline).bold()
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }.frame(width: 30, height: 30)
            }.padding(.trailing, 7)
        }
    }
    @ViewBuilder
    func NewsMessageField() -> some View {
        ZStack(alignment: .leading){
            if replyNews.isEmpty {
                if selectedOpinion != nil {
                    Text("Reply to this opinion")
                        .opacity(0.5)
                        .offset(x: 15)
                        .foregroundColor(.gray)
                        .font(.system(size: 17))
                } else {
                    Text("Add an Opinion")
                        .opacity(0.5)
                        .offset(x: 15)
                        .foregroundColor(.gray)
                        .font(.system(size: 17))
                }
            }
            TextField("", text: $replyNews, axis: .vertical)
                .focused($isEditing)
                .submitLabel(.send)
                .tint(.blue)
                .lineLimit(5)
                .padding(.leading)
                .padding(.trailing, 4)
                .frame(minHeight: 40)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(replyNewsError ? .red : .gray, lineWidth: 2)
                }
                .onChange(of: replyNews) { _, newValue in
                    if replyNews.count > 30 && !showAI {
                        withAnimation(.easeInOut(duration: 0.15)){
                            showAI = true
                        }
                    } else if replyNews.count <= 30 && showAI {
                        withAnimation(.easeInOut(duration: 0.15)){
                            showAI = false
                        }
                    }
                    
                    if !tag.isEmpty && !replyNews.contains("@\(tag)") {
                        tag = ""
                    }
                    if !inputChecker().myInputChecker(withString: replyNews, withLowerSize: 2, withUpperSize: selectedOpinion == nil ? 300 : 200, needsLower: true).isEmpty {
                        replyNewsError = true
                        if replyNews.isEmpty { replyNewsError = false }
                        guard let newValueLastChar = newValue.last else { return }
                        if newValueLastChar == "\n" {
                            replyNews.removeLast()
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    } else {
                        replyNewsError = false
                        guard let newValueLastChar = newValue.last else { return }
                        if newValueLastChar == "\n" {
                            replyNews.removeLast()
                            if let username = authViewModel.currentUser?.username, !replyNews.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                               if let id = selectedOpinion {
                                   viewModel.sendOpinionReplies(newsID: news.id ?? "", opinionID: id, caption: replyNews, user: username)
                                   if !tag.isEmpty {
                                       popRoot.alertImage = "tag.fill"
                                       popRoot.alertReason = "Tagged user notified"
                                       withAnimation {
                                           popRoot.showAlert = true
                                       }
                                       viewModel.tagUserNews(myUsername: username, otherUsername: tag, message: replyNews, newsName: news.title)
                                       tag = ""
                                   }
                                   replyNews = ""
                               } else {
                                   withAnimation(.easeOut){
                                       showAnonymous = true
                                   }
                               }
                           }
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }
        }
        .foregroundColor(colorScheme == .dark ? .white : .black)
        .background(colorScheme == .dark ? .black : .white)
        .cornerRadius(20)
    }
}

import SwiftUI
import Firebase
import Kingfisher

struct ProfileSheetView: View {
    let generator = UINotificationFeedbackGenerator()
    @Namespace var animation
    @State var selection1 = 0
    @State private var selectedFilter: TweetFilterViewModel = .hustles
    @EnvironmentObject var viewModel: ProfileViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var pop: PopToRoot
    @State private var showMessage = false
    @State private var showCall = false
    @State private var showVideoCall = false
    @State private var yearString = ""
    @State var showShop: Bool = false
    @State var selectedShop: Shop = Shop(uid: "", username: "", title: "", caption: "", price: 0, location: "", photos: [], tagJoined: "", promoted: nil, timestamp: Timestamp())
    @State private var showQuestion = false
    @State var selectedQuestion: Question = Question(uid: "", username: "", caption: "", votes: 0, timestamp: Timestamp())
    @State private var showQuestionSec = false
    @State var selectedQuestionSec: Question = Question(uid: "", username: "", caption: "", votes: 0, timestamp: Timestamp())
    @State private var seenNow = false
    let uid: String
    let photo: String
    let user: User?
    @Binding var username: String?
    @State var highlightColor: Color = .white
    @State var viewID1: String = "NA1"
    @State var viewID2: String = "NA2"
    @State var viewID3: String = "NA3"
    @State var currentAudio: String = "NA3"
    @State var tempSet = false
    @Namespace private var newsAnimation
    
    var body: some View {
        ScrollView {
            LazyVStack {
                header()
                badges()
                if let index = viewModel.currentUser {
                    middle1(index: index).padding(.top, 15)
                }
                content().padding(.top, 20)
                Color.clear.frame(height: 60)
            }
        }
        .background(Color.gray.opacity(0.2))
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .ignoresSafeArea()
        .onAppear {
            if let current = auth.currentUser, !viewModel.fetching {
                viewModel.fetching = true
                if let username = username, uid.isEmpty && user == nil {
                    viewModel.startUsername(currentUser: current, username: username)
                } else {
                    viewModel.start(uid: uid, currentUser: current, optionalUser: user)
                }
                setHighlight()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                    viewModel.fetching = false
                    setHighlight()
                }
            }
            setSeen()
        }
        .onChange(of: viewModel.currentUser) { _, _ in
            setHighlight()
        }
        .sheet(isPresented: $showShop, content: {
            SingleShopView(shopItem: selectedShop, disableUser: true, shouldCloseKeyboard: false)
                .presentationDetents([.large]).presentationDragIndicator(.hidden)
                .id(viewID1)
        })
        .sheet(isPresented: $showQuestion, content: {
            ImageQuestionView(question: selectedQuestion, disableUser: true, shouldShowTab: true)
                .presentationDetents([.large]).presentationDragIndicator(.hidden)
                .id(viewID2)
        })
        .sheet(isPresented: $showQuestionSec, content: {
            QuestionSingleView(disableUser: false, question: selectedQuestionSec, isSheet: true)
                .presentationDetents([.large]).presentationDragIndicator(.hidden)
                .id(viewID3)
        })
        .onChange(of: selectedShop) { _, _ in
            viewID1 = "\(UUID())"
        }
        .onChange(of: selectedQuestion) { _, _ in
            viewID2 = "\(UUID())"
        }
        .onChange(of: selectedQuestionSec) { _, _ in
            viewID3 = "\(UUID())"
        }
    }
    func setHighlight(){
        if let index = viewModel.currentUser {
            let elo = viewModel.users[index].user.elo
            if elo < 600 {
                highlightColor = .white
            } else if elo < 850 {
                highlightColor = .white
            } else if elo < 1300 {
                highlightColor = .green
            } else if elo < 2000 {
                highlightColor = .yellow
            } else if elo < 2900 {
                highlightColor = .red
            } else if elo >= 2900 {
                highlightColor = .blue
            }
        }
    }
    func content() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(Color(UIColor.darkGray)).opacity(0.6)
            
            RoundedRectangle(cornerRadius: 10).stroke(lineWidth: 1).foregroundStyle(highlightColor)
            
            VStack(spacing: 15){
                tweetFilter
                if let index = viewModel.currentUser {
                    tweetsView(index: index)
                }
            }.padding(5)
        }.padding(.horizontal)
    }
    func badges() -> some View {
        HStack {
            Spacer()
            HStack(spacing: 0){
                if let index = viewModel.currentUser {
                    Image("write").resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 35)
                    if viewModel.users[index].user.badges.contains("tentips"){
                        Image("tentips").resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 35)
                    }
                    if viewModel.users[index].user.badges.contains("fivejobs"){
                        Image("fivejobs").resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 35)
                    }
                    if viewModel.users[index].user.badges.contains("heart"){
                        Image("heart").resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 35)
                    }
                    if viewModel.users[index].user.badges.contains("tenhustles"){
                        Image("tenhustles").resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 35)
                    }
                    if viewModel.users[index].user.badges.contains("g_owner"){
                        Image("g_owner").resizable().aspectRatio(contentMode: .fit).frame(maxHeight: 25)
                    }
                }
            }.padding(.horizontal, 4).padding(.top, 2).background(Color(.systemBackground)).cornerRadius(10, corners: .allCorners)
        }.padding(.trailing, 5).padding(.top, 15)
    }
    func middle1(index: Int) -> some View {
        TabView(selection: $selection1) {
            VStack {
                HStack(spacing: 8){
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).foregroundStyle(Color(UIColor.darkGray)).opacity(0.6)
                        RoundedRectangle(cornerRadius: 10).stroke(lineWidth: 1).foregroundStyle(highlightColor)
                        HStack {
                            VStack {
                                HStack(spacing: 8){
                                    if let silent = viewModel.users[index].user.silent {
                                        if silent == 1 {
                                            Circle().foregroundStyle(.green).frame(width: 12, height: 12)
                                        } else if silent == 2 {
                                            Image(systemName: "moon.fill").foregroundStyle(.yellow).frame(width: 18, height: 18)
                                        } else {
                                            Image(systemName: "slash.circle.fill").foregroundStyle(.red).frame(width: 18, height: 18)
                                        }
                                    } else if seenNow {
                                        Circle().foregroundStyle(.green).frame(width: 12, height: 12)
                                    }
                                    Text(viewModel.users[index].user.fullname).font(.title2).bold()
                                        .lineLimit(1).minimumScaleFactor(0.7)
                                    Spacer()
                                }.foregroundStyle(.white).padding(.leading, 8)
                                HStack {
                                    Text("@\(viewModel.users[index].user.username)").font(.subheadline)
                                        .lineLimit(1).minimumScaleFactor(0.7)
                                    if viewModel.users[index].user.verified ?? false {
                                        Image("veriBlue")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxHeight: 20)
                                    }
                                    Spacer()
                                }.foregroundStyle(.white).padding(.leading, 8)
                                Spacer()
                                HStack {
                                    if let bio = viewModel.users[index].user.bio, !bio.isEmpty {
                                        Text(bio).font(.subheadline)
                                    } else {
                                        Text("Nothing yet...").font(.subheadline)
                                    }
                                    Spacer()
                                }.foregroundStyle(.white).padding(.leading, 8)
                            }.padding(.vertical, 8)
                            VStack {
                                let elo = viewModel.users[index].user.elo
                                if elo < 600 {
                                    Image("pawn").resizable().frame(width: 60, height: 90)
                                } else if elo < 850{
                                    Image("bishop").resizable().frame(width: 60, height: 100)
                                } else if elo < 1300{
                                    Image("knight").resizable().frame(width: 65, height: 100)
                                } else if elo < 2000{
                                    Image("rook").resizable().frame(width: 65, height: 95)
                                } else if elo < 2900{
                                    Image("queen").resizable().frame(width: 60, height: 100)
                                } else if elo >= 2900 {
                                    Image("king").resizable().frame(width: 60, height: 100)
                                }
                                Text("\(elo)").font(Font.custom("Revalia-Regular", size: 16, relativeTo: .title)).bold()
                            }.padding(.vertical, 5).padding(.trailing, 5)
                        }
                    }
                    if !viewModel.isCurrentUser {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).foregroundStyle(Color(UIColor.darkGray)).opacity(0.6)
                                RoundedRectangle(cornerRadius: 10).stroke(lineWidth: 1).foregroundStyle(highlightColor)
                                if let index = viewModel.currentUser {
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showMessage.toggle()
                                    }, label: {
                                        VStack(spacing: 6){
                                            Image(systemName: "message.fill").foregroundStyle(.white).opacity(0.9).font(.title3)
                                            Text("text").font(.caption).foregroundStyle(.white)
                                        }
                                    })
                                    .fullScreenCover(isPresented: $showMessage) {
                                        MessagesView(exception: false, user: viewModel.users[index].user, uid: viewModel.users[index].user.id ?? "", tabException: false, canCall: false)
                                    }
                                } else {
                                    VStack(spacing: 6){
                                        Image(systemName: "message.fill").foregroundStyle(.white).opacity(0.9).font(.title3)
                                        Text("text").font(.caption).foregroundStyle(.white)
                                    }
                                }
                            }
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).foregroundStyle(Color(UIColor.darkGray)).opacity(0.6)
                                RoundedRectangle(cornerRadius: 10).stroke(lineWidth: 1).foregroundStyle(highlightColor)
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    showCall.toggle()
                                }, label: {
                                    VStack(spacing: 6){
                                        Image(systemName: "phone.connection.fill").foregroundStyle(.white).opacity(0.9).font(.title3)
                                        Text("call").font(.caption).foregroundStyle(.white)
                                    }
                                })
                            }
                        }.frame(width: 40)
                        VStack(spacing: 8){
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).foregroundStyle(Color(UIColor.darkGray)).opacity(0.6)
                                RoundedRectangle(cornerRadius: 10).stroke(lineWidth: 1).foregroundStyle(highlightColor)
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    showVideoCall.toggle()
                                }, label: {
                                    VStack(spacing: 6){
                                        Image(systemName: "video.fill").foregroundStyle(.white).opacity(0.9).font(.title3)
                                        Text("FT").font(.caption).foregroundStyle(.white)
                                    }
                                })
                            }
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).foregroundStyle(Color(UIColor.darkGray)).opacity(0.6)
                                RoundedRectangle(cornerRadius: 10).stroke(lineWidth: 1).foregroundStyle(highlightColor)
                                Button(action: {
                                    if let following = auth.currentUser?.following {
                                        if following.contains(uid){
                                            viewModel.unfollow(withUid: uid)
                                            auth.currentUser?.following.removeAll(where: { $0 == uid })
                                            generator.notificationOccurred(.error)
                                        } else {
                                            viewModel.follow(withUid: uid)
                                            generator.notificationOccurred(.success)
                                            auth.currentUser?.following.append(uid)
                                            if !viewModel.startedFollowing.contains(uid) {
                                                viewModel.startedFollowing.append(uid)
                                                if let myUID = auth.currentUser?.id, let name = auth.currentUser?.fullname {
                                                    viewModel.sendNotif(taggerName: name, taggerUID: myUID, taggedUID: uid)
                                                }
                                            }
                                        }
                                    }
                                }, label: {
                                    if let following = auth.currentUser?.following, following.contains(uid) {
                                        VStack(spacing: 3){
                                            Image(systemName: "person.fill.badge.minus").foregroundStyle(.green).opacity(0.9).font(.title3)
                                            Text("Added").font(.caption2).foregroundStyle(.white)
                                        }
                                    } else {
                                        VStack(spacing: 6){
                                            Image(systemName: "person.fill.badge.plus").foregroundStyle(.white).opacity(0.9).font(.title3)
                                            Text("Follow").font(.caption2).foregroundStyle(.white)
                                        }
                                    }
                                })
                            }
                        }.frame(width: 40)
                    }
                }.padding(.horizontal)
            }.padding(.vertical, 2.5).tag(0)
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).foregroundStyle(Color(UIColor.darkGray)).opacity(0.6)
                    RoundedRectangle(cornerRadius: 10).stroke(lineWidth: 1).foregroundStyle(highlightColor)
                    VStack {
                        if let index = viewModel.currentUser {
                            HStack {
                                HStack(alignment: .bottom){
                                    Text("ELO").font(.caption)
                                    Text("\(viewModel.users[index].user.elo)").font(Font.custom("Revalia-Regular", size: 24, relativeTo: .title)).bold()
                                }
                                Spacer()
                                VStack {
                                    Text("\(viewModel.users[index].user.followers)").font(.body).bold()
                                    Text("Followers").font(.caption)
                                }
                                Spacer()
                                VStack {
                                    Text("\(viewModel.users[index].user.following.count)").font(.body).bold()
                                    Text("Following").font(.caption)
                                }
                                Spacer()
                                VStack {
                                    Text(yearString).font(.body).bold()
                                    Text("Joined").font(.caption)
                                }
                                .onAppear {
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "yyyy"
                                    yearString = dateFormatter.string(from: viewModel.users[index].user.timestamp.dateValue())
                                }
                            }
                            Spacer()
                            HStack {
                                VStack {
                                    Text("\((viewModel.users[index].tweets ?? []).count)").font(.body).bold()
                                    Text("Hustles").font(.caption)
                                }
                                Spacer()
                                VStack {
                                    Text("\(viewModel.users[index].user.completedjobs)").font(.body).bold()
                                    HStack(spacing: 2){
                                        Image(systemName: "checkmark").font(.caption).foregroundColor(.green)
                                        Text("Jobs").font(.caption)
                                    }
                                }
                                Spacer()
                                VStack {
                                    Text("\(viewModel.users[index].user.sold ?? 0)").font(.body).bold()
                                    Text("Sold").font(.caption)
                                }
                                Spacer()
                                VStack {
                                    Text("\(viewModel.users[index].user.bought ?? 0)").font(.body).bold()
                                    Text("Bought").font(.caption)
                                }
                                Spacer()
                                VStack {
                                    Text("\(viewModel.users[index].user.verifiedTips)").font(.body).bold()
                                    Text("Tips").font(.caption)
                                }
                            }
                        }
                    }.padding().padding(.vertical, 5)
                }.padding(.horizontal)
            }.padding(.vertical, 2.5).tag(1)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: 145)
    }
    func header() -> some View {
        ZStack(alignment: .bottomLeading){
            if let index = viewModel.currentUser, let back = viewModel.users[index].user.userBackground, !back.isEmpty {
                Color(red: 0.5, green: 0.6, blue: 1.0).frame(height: 135)
                KFImage(URL(string: back))
                    .resizable()
                    .scaledToFill()
                    .frame(height: 135)
                    .clipped()
                    .ignoresSafeArea()
            } else {
                Color(red: 0.5, green: 0.6, blue: 1.0).frame(height: 135)
            }
            ZStack {
                Circle().frame(width: 90, height: 90)
                    .foregroundStyle(Color(.systemBackground))
                Circle().frame(width: 90, height: 90)
                    .foregroundStyle(Color.gray.opacity(0.2))
                if let index = viewModel.currentUser, let url = viewModel.users[index].user.profileImageUrl, !url.isEmpty {
                    KFImage(URL(string: url))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 77, height: 77)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle().frame(width: 77, height: 77).foregroundStyle(.black)
                        Image(systemName: "questionmark")
                            .resizable().foregroundColor(Color(red: 0.5, green: 0.6, blue: 1.0)).frame(width: 15, height: 25)
                    }
                }
            }.padding(.leading, 25).offset(y: 39)
            
            HStack {
                Spacer()
                Menu {
                    if !viewModel.isCurrentUser {
                        Button(role: .destructive, action: {
                            UserService().reportContent(type: "User", postID: uid)
                        }) {
                            Label("Report", systemImage: "flag.fill")
                        }
                        Button(role: .destructive, action: {
                            if auth.currentUser?.blockedUsers == nil {
                                auth.currentUser?.blockedUsers = []
                            }
                            auth.currentUser?.blockedUsers?.append(uid)
                            UserService().blockUser(uid: uid)
                        }) {
                            Label("Block", systemImage: "hand.raised.fill")
                        }
                    }
                    Button {
                        withAnimation {
                            pop.alertReason = "Profile URL copied"
                            pop.alertImage = "link"
                            pop.showAlert = true
                        }
                        UIPasteboard.general.string = "https://hustle.page/profile/\(uid)/"
                    } label: {
                        Label("Copy Profile URL", systemImage: "link")
                    }
                } label: {
                    ZStack {
                        Circle().fill(.ultraThinMaterial)
                            .frame(width: 40)
                        Image(systemName: "ellipsis")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }.scaleEffect(0.85)
                }.offset(y: -80)
            }.padding(.trailing, 10)
        }
    }
    var tweetFilter: some View {
        HStack {
            ForEach(TweetFilterViewModel.allCases, id: \.rawValue){ item in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeIn(duration: 0.2)){
                        selectedFilter = item
                    }
                    if let index = viewModel.currentUser {
                        if selectedFilter == .likes && (viewModel.users[index].likedTweets ?? []).isEmpty {
                            viewModel.fetchLikedTweets()
                        }
                        if selectedFilter == .jobs && (viewModel.users[index].listJobs ?? []).isEmpty {
                            viewModel.fetchUserJobs(userPhoto: auth.currentUser?.profileImageUrl, isCurrentUser: auth.currentUser?.id == viewModel.users[index].user.id)
                        }
                        if selectedFilter == .sale && (viewModel.users[index].forSale ?? []).isEmpty {
                            viewModel.fetchUserSales(userPhoto: auth.currentUser?.profileImageUrl, isCurrentUser: auth.currentUser?.id == viewModel.users[index].user.id)
                        }
                        if selectedFilter == .questions && (viewModel.users[index].questions ?? []).isEmpty {
                            viewModel.fetchUserQuestions(userPhoto: auth.currentUser?.profileImageUrl, isCurrentUser: auth.currentUser?.id == viewModel.users[index].user.id)
                        }
                    }
                } label: {
                    VStack(spacing: 2){
                        Text(item.title)
                            .font(.subheadline)
                            .fontWeight(selectedFilter == item ? .semibold : .regular)
                            .foregroundColor(selectedFilter == item ? Color(red: 0.5, green: 0.6, blue: 1.0) : .white)
                        
                        if selectedFilter == item {
                            Capsule()
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 1.0))
                                .frame(height: 3)
                                .matchedGeometryEffect(id: "filter", in: animation)
                        } else {
                            Capsule()
                                .foregroundColor(Color(.clear))
                                .frame(height: 3)
                        }
                    }
                }
            }
        }
    }
    func tweetsView(index: Int) -> some View {
        LazyVStack {
            if selectedFilter == .hustles {
                if let hustles = viewModel.users[index].tweets {
                    if hustles.isEmpty {
                        HStack {
                            Spacer()
                            Text("Nothing here...").gradientForeground(colors: [.green, .blue]).font(.system(size: 25))
                            Spacer()
                        }.padding(.vertical)
                    } else {
                        ForEach(hustles) { tweet in
                            TweetRowView(tweet: tweet, edit: false, canShow: false, canSeeComments: false, map: false, currentAudio: $currentAudio, isExpanded: $tempSet, animationT: animation, seenAllStories: false, isMain: false, showSheet: $tempSet, newsAnimation: newsAnimation)
                            if tweet != hustles.last {
                                Divider().overlay(.gray).padding(.bottom, 6).opacity(0.4)
                            }
                        }
                    }
                } else {
                    VStack {
                        ForEach(0..<7){ i in
                            LoadingFeed(lesson: "")
                        }
                    }.shimmering()
                }
            } else if selectedFilter == .jobs {
                if let jobs = viewModel.users[index].listJobs {
                    if jobs.isEmpty {
                        HStack {
                            Spacer()
                            Text("Nothing here...").gradientForeground(colors: [.green, .blue]).font(.system(size: 25))
                            Spacer()
                        }.padding(.vertical)
                    } else {
                        ForEach(jobs){ item in
                            JobsRowView(canShowProfile: false, remote: item.remote, job: item.job, is100: false, canMessage: false)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                        }
                    }
                } else {
                    VStack {
                        ForEach(0..<7){ i in
                            LoadingFeed(lesson: "")
                        }
                    }.shimmering()
                }
            } else if selectedFilter == .likes {
                if let liked = viewModel.users[index].likedTweets {
                    if liked.isEmpty {
                        HStack {
                            Spacer()
                            Text("Nothing here...").gradientForeground(colors: [.green, .blue]).font(.system(size: 25))
                            Spacer()
                        }.padding(.vertical)
                    } else {
                        ForEach(liked){ tweet in
                            TweetRowView(tweet: tweet, edit: false, canShow: false, canSeeComments: false, map: false, currentAudio: $currentAudio, isExpanded: $tempSet, animationT: animation, seenAllStories: false, isMain: false, showSheet: $tempSet, newsAnimation: newsAnimation)
                            if tweet != liked.last {
                                Divider().overlay(.gray).padding(.bottom, 6).opacity(0.4)
                            }
                        }
                    }
                } else {
                    VStack {
                        ForEach(0..<7){ i in
                            LoadingFeed(lesson: "")
                        }
                    }.shimmering()
                }
            } else if selectedFilter == .sale {
                if let sale = viewModel.users[index].forSale {
                    if sale.isEmpty {
                        HStack {
                            Spacer()
                            Text("Nothing here...").gradientForeground(colors: [.green, .blue]).font(.system(size: 25))
                            Spacer()
                        }.padding(.vertical)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                            ForEach(sale){ shop in
                                Button {
                                    selectedShop = shop
                                    showShop = true
                                } label: {
                                    ShopRowView(shopItem: shop, isSheet: true)
                                }
                            }
                        }.padding(.horizontal, 5)
                    }
                } else {
                    VStack {
                        ForEach(0..<7){ i in
                            LoadingFeed(lesson: "")
                        }
                    }.shimmering()
                }
            } else {
                if let ques = viewModel.users[index].questions {
                    if ques.isEmpty {
                        HStack {
                            Spacer()
                            Text("Nothing here...").gradientForeground(colors: [.green, .blue]).font(.system(size: 25))
                            Spacer()
                        }.padding(.vertical)
                    } else {
                        ForEach(ques){ question in
                            if question.image1 == nil {
                                Button {
                                    selectedQuestionSec = question
                                    showQuestionSec = true
                                } label: {
                                    QuestionRowView(question: question, bottomPad: false).padding(.bottom, 8)
                                }
                            } else {
                                Button {
                                    selectedQuestion = question
                                    showQuestion = true
                                } label: {
                                    ImageQuestionRow(question: question, bottomPad: false).padding(.bottom, 8)
                                }
                            }
                        }
                    }
                } else {
                    VStack {
                        ForEach(0..<7){ i in
                            LoadingFeed(lesson: "")
                        }
                    }.shimmering()
                }
            }
        }
    }
    func setSeen(){
        if let index = viewModel.currentUser {
            if let lastTime = viewModel.users[index].user.lastSeen {
                let dateString = lastTime.dateValue().formatted(.dateTime.month().day().year().hour().minute())
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
                if let date = dateFormatter.date(from:dateString){
                    if Calendar.current.isDateInToday(date){
                        seenNow = true
                    } else {
                        seenNow = false
                    }
                } else {
                    seenNow = false
                }
            } else {
                seenNow = false
            }
        }
    }
}

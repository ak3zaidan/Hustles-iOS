import SwiftUI
import Firebase

struct NewsReplyView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: ExploreViewModel
    @EnvironmentObject var auth: AuthViewModel
    @State var dateFinal: String = ""
    @State var showReps: Bool = false
    @State var canLoad: Bool = true
    @State var shouldSet: Bool = true
    @State var showUser = false
    @State var userUsername: String? = nil

    let newsID: String
    let reply: Reply
    @Binding var binded_string: String?
    let noNavStack: Bool
    
    var body: some View {
        VStack(alignment: .leading){
            VStack(spacing: 1){
                VStack(spacing: 1){
                    HStack {
                        if let username = reply.username {
                            if noNavStack {
                                Button {
                                    userUsername = username
                                    showUser = true
                                } label: {
                                    Text("@\(username):").font(.system(size: 18))
                                        .foregroundStyle(.blue)
                                }
                            } else {
                                NavigationLink {
                                    ProfileView(showSettings: false, showMessaging: true, uid: reply.id ?? "", photo: "", user: nil, expand: true, isMain: false)
                                        .dynamicTypeSize(.large)
                                } label: {
                                    Text("@\(username):").font(.system(size: 18))
                                        .foregroundStyle(.blue)
                                }
                            }
                        } else {
                            Text("Anonymous:").font(.system(size: 18))
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                    }
                    HStack {
                        LinkedText(reply.response, tip: false, isMess: nil)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                        Spacer()
                    }
                }
                HStack {
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        binded_string = reply.id
                    } label: {
                        Image(systemName: "message").foregroundColor(.blue).font(.system(size: 15))
                    }.padding(.trailing)

                    Button {
                        if reply.actions ?? 0 > 0 {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if shouldSet {
                                shouldSet = false
                                viewModel.setOpinionReplies(newsID: newsID, opinionID: reply.id ?? "", blocked: auth.currentUser?.blockedUsers ?? [])
                                Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                    shouldSet = true
                                }
                            }
                            withAnimation {
                                showReps.toggle()
                            }
                        }
                    } label: {
                        Text("\(reply.actions ?? 0) replies").font(.subheadline).foregroundColor(.blue)
                    }.padding(.trailing)

                    Text(dateFinal).font(.caption).bold().foregroundStyle(.gray)
                        .onAppear {
                            dateFinal = getMessageTime(date: reply.timestamp.dateValue())
                        }
                }.padding(.trailing).padding(.top, 7)
            }
            .multilineTextAlignment(.leading)
            .padding(5)
            .background(Color.gray.opacity(colorScheme == .dark ? 0.15 : 0.1))
            .cornerRadius(15)
            .dynamicTypeSize(.large)
            
            HStack(alignment: .top){
                if showReps {
                    RoundedRightAngleShape()
                        .rotation(.degrees(-90))
                        .stroke(Color.gray, lineWidth: 4)
                        .frame(width: 35, height: 35)
                    VStack(spacing: 5){
                        if let x = viewModel.opinion_Reply.first(where: { $0.0 == (reply.id ?? "") }){
                            ForEach(x.1){ reply in
                                OpinionReplyView(reply: reply, noNavStack: noNavStack)
                            }
                            if let num = reply.actions {
                                if !x.1.isEmpty && (x.1.count + 5) < num {
                                    Button {
                                        if canLoad {
                                            canLoad = false
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                                canLoad = true
                                            }
                                            viewModel.getOpinionReplies(newsID: newsID, opinionID: reply.id ?? "", blocked: auth.currentUser?.blockedUsers ?? [])
                                        }
                                    } label: {
                                        Text("Load More").font(.subheadline).foregroundColor(.blue)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 3)
                                    }.background(Color.gray.opacity(0.5)).cornerRadius(10)
                                }
                            }
                        }
                    }
                }
            }.padding(.leading, 8).padding(.top, 2)
        }
        .padding(.horizontal, 7)
        .sheet(isPresented: $showUser) {
            NavigationStack {
                ProfileSheetView(uid: "", photo: "", user: nil, username: $userUsername)
            }.presentationDetents([.large])
        }
    }
}

struct OpinionReplyView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var dateFinal: String = ""
    @State var showUser = false
    @State var userUsername: String? = nil
    
    let reply: Reply
    let noNavStack: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1){
            HStack {
                if let username = reply.username {
                    if noNavStack {
                        Button {
                            userUsername = username
                            showUser = true
                        } label: {
                            Text("@\(username):").font(.system(size: 16)).bold()
                                .foregroundStyle(.blue)
                        }
                    } else {
                        NavigationLink {
                            ProfileView(showSettings: false, showMessaging: true, uid: reply.uid ?? "", photo: "", user: nil, expand: true, isMain: false)
                                .dynamicTypeSize(.large)
                        } label: {
                            Text("@\(username):").font(.system(size: 16)).bold()
                                .foregroundStyle(.blue)
                        }
                    }
                } else {
                    Text("Anonymous:").font(.system(size: 16)).bold().foregroundStyle(.gray)
                }
                Spacer()
                Text(dateFinal).font(.caption).padding(.trailing, 4).foregroundStyle(.gray)
            }
            HStack {
                LinkedText(reply.response, tip: false, isMess: nil).font(.system(size: 16))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                Spacer()
            }
        }
        .padding(5)
        .background(Color.blue.opacity(colorScheme == .dark ? 0.2 : 0.1))
        .cornerRadius(15)
        .multilineTextAlignment(.leading)
        .dynamicTypeSize(.large)
        .onAppear {
            dateFinal = getMessageTime(date: reply.timestamp.dateValue())
        }
        .sheet(isPresented: $showUser) {
            NavigationStack {
                ProfileSheetView(uid: "", photo: "", user: nil, username: $userUsername)
            }.presentationDetents([.large])
        }
    }
}

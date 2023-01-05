import SwiftUI

struct FeedNotificationView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @Environment(\.colorScheme) var colorScheme
    let close: () -> Void
    
    var body: some View {
        VStack {
            HStack(spacing: 8){
                Button {
                    close()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                    Text("Notifications").bold()
                }.font(.title)
                Spacer()
            }.padding(.leading)
            if !viewModel.notifs.isEmpty || !viewModel.secondary_notifs.isEmpty {
                List {
                    SwipeViewGroup {
                        ForEach(viewModel.notifs){ element in
                            SwipeView {
                                NotificationRowColor(notif: element)
                                    .listRowSeparatorTint(colorScheme == .dark ? .white : .gray)
                                    .contentShape(Rectangle())
                            } trailingActions: { _ in
                                SwipeAction {
                                    if let id = element.id {
                                        withAnimation {
                                            viewModel.notifs.removeAll(where: { $0.id == id })
                                            viewModel.deleteNotication(id: id)
                                        }
                                    }
                                } label: { _ in
                                    Image(systemName: "trash").foregroundStyle(.white).font(.title3)
                                } background: { _ in
                                    Color.red
                                }
                                .allowSwipeToTrigger()
                            }
                        }
                        ForEach(viewModel.secondary_notifs){ element in
                            SwipeView {
                                secondaryNotifs(text1: element.text1, text2: element.text2)
                                    .listRowSeparatorTint(colorScheme == .dark ? .white : .gray)
                                    .contentShape(Rectangle())
                            } trailingActions: { _ in
                                SwipeAction {
                                    if let index = viewModel.secondary_notifs.firstIndex(where: { $0.text1 == element.text1 }) {
                                        viewModel.secondary_notifs.remove(at: index)
                                    }
                                } label: { _ in
                                    Image(systemName: "trash").foregroundStyle(.white).font(.title3)
                                } background: { _ in
                                    Color.red
                                }
                                .allowSwipeToTrigger()
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets()).listStyle(PlainListStyle())
            } else {
                List {
                    HStack {
                        Spacer()
                        VStack(spacing: 18){
                            Text("Nothing here yet...")
                                .gradientForeground(colors: [.blue, .purple])
                                .font(.headline).bold()
                            LottieView(loopMode: .playOnce, name: "nofound")
                                .scaleEffect(0.3)
                                .frame(width: 100, height: 100)
                        }
                        Spacer()
                    }
                    .listRowSeparatorTint(.clear).contentShape(Rectangle())
                }.listRowInsets(EdgeInsets()).listStyle(PlainListStyle())
            }
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(edges: .bottom)
        .onAppear(perform: {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            if let user = auth.currentUser, let id = user.id, !viewModel.gotNotifications {
                if let prof = profile.users.first(where: { $0.user.id ?? "" == id }) {
                    viewModel.getNotifications(profile: prof)
                } else {
                    viewModel.getNotifications(profile: Profile(user: user, tweets: [], listJobs: [], likedTweets: [], forSale: [], questions: []))
                }
            }
        })
        .onChange(of: auth.currentUser) { _, _ in
            if let user = auth.currentUser, let id = user.id, !viewModel.gotNotifications {
                if let prof = profile.users.first(where: { $0.user.id ?? "" == id }) {
                    viewModel.getNotifications(profile: prof)
                } else {
                    viewModel.getNotifications(profile: Profile(user: user, tweets: [], listJobs: [], likedTweets: [], forSale: [], questions: []))
                }
            }
        }
        .onChange(of: popRoot.tap, { _, _ in
            if popRoot.tap == 1 {
                presentationMode.wrappedValue.dismiss()
                popRoot.tap = 0
            }
        })
    }
    func secondaryNotifs(text1: String, text2: String) -> some View {
        HStack(alignment: .top){
            Image("nobackorange").resizable().frame(width: 25, height: 38).scaleEffect(1.2)
            VStack {
                HStack {
                    Text("Post Notification").font(.subheadline)
                    Spacer()
                    Text("Now").font(.system(size: 16))
                    Image(systemName: "envelope").foregroundColor(.blue)
                }
                HStack {
                    Text(text1).font(.system(size: 18)).multilineTextAlignment(.leading).bold()
                    Spacer()
                }.padding(.top, 2)
                HStack {
                    Text(text2).font(.system(size: 16)).foregroundColor(.gray).multilineTextAlignment(.leading)
                    Spacer()
                }.padding(.top, 1)
            }.padding(.top, 8)
        }
    }
}

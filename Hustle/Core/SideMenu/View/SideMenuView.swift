import SwiftUI
import Kingfisher
import Firebase

struct SideMenuView: View {
    @EnvironmentObject var messageLogOut: MessageViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var explore: ExploreViewModel
    @EnvironmentObject var ads: UploadAdViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var stocks: StockViewModel
    @EnvironmentObject var feed: FeedViewModel
    @EnvironmentObject var globe: GlobeViewModel
    @EnvironmentObject var gc: GroupChatViewModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var showPhoneSheet: Bool
    @Binding var showFriends: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20){
            ForEach(SideMenuViewModel.allCases, id: \.rawValue){ viewModel in
                if viewModel == .Account {
                    NavigationLink {
                        AccountView()
                    } label: {
                        SideMenuOptionRowView(viewModel: viewModel)
                    }.padding(.top, 10)
                } else if viewModel == .help {
                    NavigationLink{
                        HelpView()
                    } label: {
                        SideMenuOptionRowView(viewModel: viewModel)
                    }
                } else if viewModel == .privacy {
                    NavigationLink{
                        PrivacyView()
                    } label: {
                        SideMenuOptionRowView(viewModel: viewModel)
                    }
                } else if viewModel == .Advertising {
                    NavigationLink {
                        AdvertisingView()
                    } label: {
                        SideMenuOptionRowView(viewModel: viewModel)
                    }
                } else if viewModel == .howTo {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if let phone = authViewModel.currentUser?.phoneNumber, !phone.isEmpty {
                            if profile.allContacts.isEmpty {
                                fetchContacts { final in
                                    self.profile.allContacts = final
                                    self.profile.getContacts()
                                    self.showFriends = true
                                }
                            } else {
                                if !profile.gettingContacts && profile.contactFriends.isEmpty {
                                    self.profile.getContacts()
                                }
                                showFriends = true
                            }
                        } else {
                            showPhoneSheet = true
                        }
                    } label: {
                        HStack(spacing: 16){
                            Image(systemName: "person.3").font(.headline).foregroundColor(.gray)
                            Text("My Friends")
                                .font(.subheadline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer()
                        }
                        .frame(height: 40)
                        .padding(.horizontal)
                    }
                } else if viewModel == .logout {
                    Button {
                        ads.myAds = []
                        explore.avoidReplies = []
                        explore.joinedGroups = []
                        explore.userGroup = nil
                        messageLogOut.chats = []
                        messageLogOut.gotConversations = false
                        messageLogOut.currentChat = nil
                        messageLogOut.priv_Key_Saved = nil
                        messageLogOut.gotNotifications = false
                        messageLogOut.notifs = []
                        messageLogOut.secondary_notifs = []
                        profile.currentUser = nil
                        profile.allContacts = []
                        profile.contactFriends = []
                        profile.exeFuncToDisplay = false
                        profile.isCurrentUser = false
                        profile.tokenToShow = ""
                        profile.unlockToShow = nil
                        profile.blockedUsers = []
                        authViewModel.signOut()
                        stocks.gotUsersData = false
                        feed.followers = []
                        popRoot.tab = 1
                        popRoot.lastSeen = nil
                        globe.option = 2
                        gc.chats = []
                    } label: {
                        SideMenuOptionRowView(viewModel: viewModel)
                    }
                }
            }
            Spacer()
        }
        .background((colorScheme == .dark ?
             LinearGradient(gradient: Gradient(colors: [Color(red: 40/255, green: 40/255, blue: 40/255), Color.black]),
                            startPoint: .top,
                            endPoint: .bottom)
             :
                LinearGradient(gradient: Gradient(colors: [Color.white, Color.white]),
                               startPoint: .top,
                               endPoint: .bottom)
            )
        )
        .cornerRadius(40, corners: [.topLeft, .topRight])
    }
}

struct LogOutButton: View {
    @EnvironmentObject var messageLogOut: MessageViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var explore: ExploreViewModel
    @EnvironmentObject var ads: UploadAdViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var stocks: StockViewModel
    @EnvironmentObject var feed: FeedViewModel
    @EnvironmentObject var globe: GlobeViewModel
    @EnvironmentObject var gc: GroupChatViewModel
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("We could not find your Account.")
                        .font(.headline)
                    Text("Check your network or reach out to us.")
                        .font(.subheadline).padding(.top)
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding()
            .padding(.top, 80)
            
            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                ads.myAds = []
                explore.avoidReplies = []
                explore.joinedGroups = []
                explore.userGroup = nil
                messageLogOut.chats = []
                messageLogOut.gotConversations = false
                messageLogOut.currentChat = nil
                messageLogOut.priv_Key_Saved = nil
                messageLogOut.gotNotifications = false
                messageLogOut.notifs = []
                messageLogOut.secondary_notifs = []
                profile.currentUser = nil
                profile.exeFuncToDisplay = false
                profile.isCurrentUser = false
                profile.tokenToShow = ""
                profile.allContacts = []
                profile.contactFriends = []
                profile.blockedUsers = []
                profile.unlockToShow = nil
                authViewModel.signOut()
                stocks.gotUsersData = false
                feed.followers = []
                popRoot.tab = 1
                popRoot.lastSeen = nil
                globe.option = 2
                gc.chats = []
            } label: {
                Text("Sign out")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemIndigo))
                    .cornerRadius(12)
                    .padding()
            }.padding(.bottom, 50)
        }
    }
}

import SwiftUI
import Combine
import UIKit
import Kingfisher

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var pop: PopToRoot
    @Environment(\.colorScheme) var colorScheme
    @State var messageOrder = [String]()
    @State var storiesUidOrder = [String]()
    @State var mutedStories = [String]()
    @State var noStoriesFound: Bool = false
    let newsAnimation: Namespace.ID
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if pop.tab == 1 {
                FullSwipeNavigationStack {
                    FeedBaseView(storiesUidOrder: $storiesUidOrder, mutedStories: $mutedStories, noneFound: $noStoriesFound, newsAnimation: newsAnimation)
                }
            } else if pop.tab == 2 {
                FullSwipeNavigationStack {
                    JobsView()
                }
            } else if pop.tab == 3 {
                ExploreView(newsAnimation: newsAnimation)
            } else if pop.tab == 4 {
                FullSwipeNavigationStack {
                    QuestionView()
                }
            } else if pop.tab == 5 {
                MessageBaseView(messageOrder: $messageOrder)
            } else if pop.tab == 6 {
                FullSwipeNavigationStack {
                    if let user = authViewModel.currentUser {
                        MainProfile(uid: user.id ?? "", photo: user.profileImageUrl ?? "", user: user)
                    } else {
                        LogOutButton()
                    }
                }
            }
            if pop.tab != 5 {
                tabBarMain()
            }
        }.tint(colorScheme == .dark ?  .white : .black)
    }
}

struct tabBarMain: View {
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var globe: GlobeViewModel
    let manager = GlobeLocationManager()
    @State var lower: [String] = ["iPhone 8", "iPhone 8 Plus", "iPhone SE", "iPad"]
    
    var body: some View {
        HStack {
            TabBarButton1()
            TabBarButton2()
            TabBarButton3()
            TabBarButton4()
            TabBarButton5()
            TabBarButton6()
        }
        .padding(.top, 10)
        .padding(.bottom, 35)
        .background(.regularMaterial.opacity(popRoot.dimTab ? 0.5 : 1.0))
        .overlay(alignment: .top, content: {
            if let value = popRoot.uploadRate, value > 0.0 {
                HStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.orange.gradient)
                        .frame(width: widthOrHeight(width: true) * value, height: 2.5)
                    Spacer()
                }.transition(.opacity)
            }
        })
        .offset(y: popRoot.hideTabBar ? 250 : 0)
        .offset(y: lower.contains(UIDevice.modelName) ? 30 : 0)
        .onChange(of: popRoot.tab) { _, _ in
            seenNow()
        }
    }
    func seenNow(){
        if (auth.currentUser?.silent ?? 0) != 4 {
            if let date = popRoot.lastSeen {
                let calendar = Calendar.current
                let sixMinAgo = calendar.date(byAdding: .minute, value: -6, to: Date())!
                
                if date < sixMinAgo {
                    popRoot.lastSeen = Date()
                    UserService().seenNow()
                    updateBattery()
                    updateLocation()
                }
            } else {
                popRoot.lastSeen = Date()
                UserService().seenNow()
                updateBattery()
                updateLocation()
            }
        }
    }
    func updateBattery() {
        if let user = auth.currentUser {
            
            UIDevice.current.isBatteryMonitoringEnabled = true
            let level = Double(UIDevice.current.batteryLevel)
            
            if level >= 0.0 && level <= 1.0 {
                if let battery = user.currentBatteryPercentage {
                    if abs(battery - level) > 0.2 {
                        auth.currentUser?.currentBatteryPercentage = level
                        UserService().updateUserBattery(percent: level)
                    }
                } else {
                    auth.currentUser?.currentBatteryPercentage = level
                    UserService().updateUserBattery(percent: level)
                }
            }
        }
    }
    func updateLocation() {
        if let user = auth.currentUser {
            if let location = user.currentLocation {
                manager.requestLocation() { place in
                    if !place.0.isEmpty && !place.1.isEmpty {
                        let lat = place.2
                        let long = place.3
                        globe.currentLocation = myLoc(country: place.1, state: place.4, city: place.0, lat: lat, long: long)
                        if lat != 0.0 && long != 0.0 {
                            let parts = location.split(separator: ",")
                            if parts.count == 2 {
                                let oldLat = Double(parts[0]) ?? 0.0
                                let oldLong = Double(parts[1]) ?? 0.0
                                
                                if areCoordinatesMoreThan100FeetApart(lat1: lat, lon1: long, lat2: oldLat, lon2: oldLong) {
                                    let newString = "\(lat),\(long)"
                                    auth.currentUser?.currentLocation = newString
                                    UserService().updateUserLocation(newString: newString)
                                }
                            } else {
                                let newString = "\(lat),\(long)"
                                auth.currentUser?.currentLocation = newString
                                UserService().updateUserLocation(newString: newString)
                            }
                        }
                    }
                }
            } else {
                manager.requestLocation() { place in
                    if !place.0.isEmpty && !place.1.isEmpty {
                        let lat = place.2
                        let long = place.3
                        globe.currentLocation = myLoc(country: place.1, state: place.4, city: place.0, lat: lat, long: long)
                        if lat != 0.0 && long != 0.0 {
                            let newString = "\(lat),\(long)"
                            auth.currentUser?.currentLocation = newString
                            UserService().updateUserLocation(newString: newString)
                        }
                    }
                }
            }
        }
    }
}

struct TabBarButton1: View {
    @EnvironmentObject var popRoot: PopToRoot
    @State var bounce = false
    
    var body: some View {
        Button {
            DispatchQueue.main.async {
                if popRoot.tab == 1 {
                    popRoot.tap = 1
                }
                popRoot.tab = 1
            }
            if popRoot.dimTab {
                withAnimation {
                    popRoot.dimTab = false
                }
            }
        } label: {
            VStack {
                Image(systemName: popRoot.tab == 1 ? "house.fill" : "house").font(.title2)
                    .frame(height: 23).symbolEffect(.bounce, value: bounce)
                Text("Home").font(.system(size: 10))
            }
            .foregroundColor(popRoot.tab == 1 ? .orange : .primary.opacity(0.5))
            .frame(maxWidth: .infinity)
        }
        .onAppear(perform: {
            if popRoot.tab == 1 {
                bounce.toggle()
            }
        })
        .contextMenu {
            Button {
                
            } label: {
                Label("Live Streams", systemImage: "livephoto")
            }
            Button {
                
            } label: {
                Label("Spaces", systemImage: "waveform")
            }
            Button {
                
            } label: {
                Label("Markets", systemImage: "dollarsign")
            }
            Button {
                
            } label: {
                Label("News", systemImage: "newspaper")
            }
        }
    }
}

struct TabBarButton2: View {
    @EnvironmentObject var popRoot: PopToRoot
    @State var bounce = false
    
    var body: some View {
        Button {
            bounce.toggle()
            DispatchQueue.main.async {
                if popRoot.tab == 2 {
                    popRoot.tap = 2
                }
                popRoot.tab = 2
            }
            if popRoot.dimTab {
                withAnimation {
                    popRoot.dimTab = false
                }
            }
        } label: {
            VStack {
                if popRoot.Job_or_Shop {
                    Image(systemName: popRoot.tab == 2 ? "screwdriver.fill" : "screwdriver").font(.title2)
                        .frame(height: 23).symbolEffect(.bounce, value: bounce)
                    Text("Jobs").font(.system(size: 10))
                } else {
                    Image(systemName: popRoot.tab == 2 ? "cart.fill" : "cart").font(.title2)
                        .frame(height: 23).symbolEffect(.bounce, value: bounce)
                    Text("Shop").font(.system(size: 10))
                }
            }
            .foregroundColor(popRoot.tab == 2 ? .orange : .primary.opacity(0.5))
            .frame(maxWidth: .infinity)
        }
        .onAppear(perform: {
            if popRoot.tab == 2 {
                bounce.toggle()
            }
        })
    }
}

struct TabBarButton3: View {
    @EnvironmentObject var popRoot: PopToRoot
    @State var bounce = false
    
    var body: some View {
        Button {
            bounce.toggle()
            DispatchQueue.main.async {
                if popRoot.tab == 3 {
                    if !popRoot.Explore_or_Video {
                        popRoot.Hide_Video = true
                        withAnimation {
                            popRoot.Explore_or_Video = true
                        }
                    } else {
                        popRoot.tap = 3
                    }
                }
                popRoot.tab = 3
            }
            if popRoot.dimTab {
                withAnimation {
                    popRoot.dimTab = false
                }
            }
        } label: {
            VStack {
               if popRoot.Explore_or_Video {
                   Image(systemName: "magnifyingglass").font(.title2)
                       .frame(height: 23).symbolEffect(.bounce, value: bounce)
               } else {
                   Image(systemName: popRoot.tab == 3 ? "video.square.fill" : "video.square").font(.title2)
                       .frame(height: 23).symbolEffect(.bounce, value: bounce)
               }
               Text("Explore").font(.system(size: 10))
            }
            .foregroundColor(popRoot.tab == 3 ? .orange : .primary.opacity(0.5))
            .frame(maxWidth: .infinity)
        }
        .onAppear(perform: {
            if popRoot.tab == 3 {
                bounce.toggle()
            }
        })
    }
}

struct TabBarButton4: View {
    @EnvironmentObject var popRoot: PopToRoot
    @State var bounce = false
    
    var body: some View {
        Button {
            bounce.toggle()
            DispatchQueue.main.async {
                if popRoot.tab == 4 {
                    popRoot.tap = 4
                }
                popRoot.tab = 4
            }
            if popRoot.dimTab {
                withAnimation {
                    popRoot.dimTab = false
                }
            }
        } label: {
            VStack {
                Image(systemName: popRoot.tab == 4 ? "bolt.fill" : "bolt").font(.title2)
                    .frame(height: 23).symbolEffect(.bounce, value: bounce)
                Text("AI").font(.system(size: 10))
            }
            .foregroundColor(popRoot.tab == 4 ? .orange : .primary.opacity(0.5))
            .frame(maxWidth: .infinity)
        }
        .onAppear(perform: {
            if popRoot.tab == 4 {
                bounce.toggle()
            }
        })
    }
}

struct TabBarButton5: View {
    @EnvironmentObject var popRoot: PopToRoot
    @State var bounce = false
    
    var body: some View {
        Button {
            bounce.toggle()
            DispatchQueue.main.async {
                if popRoot.tab == 5 {
                    popRoot.tap = 5
                }
                popRoot.tab = 5
            }
            if popRoot.dimTab {
                withAnimation {
                    popRoot.dimTab = false
                }
            }
        } label: {
            VStack {
                Image(systemName: popRoot.tab == 5 ? "message.fill" : "message").font(.title2)
                    .frame(height: 23).symbolEffect(.bounce, value: bounce)
                Text("Chats").font(.system(size: 10))
            }
            .foregroundColor(popRoot.tab == 5 ? .orange : .primary.opacity(0.5))
            .frame(maxWidth: .infinity)
        }
        .onAppear(perform: {
            if popRoot.tab == 5 {
                bounce.toggle()
            }
        })
    }
}

struct TabBarButton6: View {
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
    @State var bounce = false
    @State var cornerRad = 0
    @State var offset: CGFloat = -80.0
    @State var size: CGFloat = 50.0
    
    var body: some View {
        Button {
            bounce.toggle()
            DispatchQueue.main.async {
                if popRoot.tab == 6 {
                    popRoot.tap = 6
                }
                popRoot.tab = 6
            }
            if popRoot.dimTab {
                withAnimation {
                    popRoot.dimTab = false
                }
            }
        } label: {
            VStack {
                Image(systemName: popRoot.tab == 6 ? "person.crop.circle.fill" : "person.crop.circle").font(.title2)
                    .frame(height: 23).symbolEffect(.bounce, value: bounce)
                Text("You").font(.system(size: 10))
            }
            .foregroundColor(popRoot.tab == 6 ? .orange : .primary.opacity(0.5))
            .frame(maxWidth: .infinity)
        }
        .onAppear(perform: {
            if popRoot.tab == 6 {
                bounce.toggle()
            }
        })
        .contextMenu {
            Button(role: .destructive){
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
                Label("Log Out", systemImage: "arrow.down.backward.square")
            }
        }
        .overlay {
            if !popRoot.saveImageAnim.isEmpty {
                KFImage(URL(string: popRoot.saveImageAnim))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: CGFloat(cornerRad)))
                    .offset(y: offset)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                cornerRad = 40
                                offset = -10.0
                                size = 0.0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                popRoot.saveImageAnim = ""
                                cornerRad = 0
                                offset = -80.0
                                size = 50.0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                bounce.toggle()
                            }
                        }
                    }
            }
        }
    }
}

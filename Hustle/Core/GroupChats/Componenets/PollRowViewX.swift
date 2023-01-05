import SwiftUI
import Firebase
import Kingfisher

struct PollRowViewChat: View {
    @Environment(\.colorScheme) var colorScheme
    let question: String
    let choice1: String
    let choice2: String
    let choice3: String?
    let choice4: String?
    @State var count1: Int
    @State var count2: Int
    @State var count3: Int?
    @State var count4: Int?
    @State var p1: Double = 0.0
    @State var p2: Double = 0.0
    @State var p3: Double = 0.0
    @State var p4: Double = 0.0
    
    let messageID: String
    let groupID: String
    let isGC: Bool
    let isDevGroup: Bool
    let squareName: String
    
    @State var whoVoted: [String]
    let timestamp: Timestamp
    
    @State var dateFinal: String = "0 days"
    @EnvironmentObject var viewModel: FeedViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var groupChat: GroupChatViewModel
    @EnvironmentObject var channelModel: GroupViewModel
    @EnvironmentObject var messageModel: MessageViewModel
    @EnvironmentObject var profile: ProfileViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @State var showUserSheet: Bool = false
    @State var whichOption: Int = 1
    @Binding var showUser: Bool
    @Binding var selectedUser: User?
    @State var fetchingUsers: Bool = false
    @State var users: [User] = []
    @State var appeared: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10){
            
            Text(question).font(.system(size: 17)).multilineTextAlignment(.leading)
            
            ZStack {
                if viewModel.votedPosts.contains(messageID) || whoVoted.contains(where: { $0.contains(auth.currentUser?.id ?? "NA") }) {
                    let total = 2 + (choice3 == nil ? 0 : 1) + (choice4 == nil ? 0 : 1)
                    GeometryReader(content: { geometry in
                        VStack(spacing: 5){
                            status(p: p1, choice: choice1, width: geometry.size.width, option: 1)
                            status(p: p2, choice: choice2, width: geometry.size.width, option: 2)
                            if let choice = choice3 {
                                status(p: p3, choice: choice, width: geometry.size.width, option: 3)
                            }
                            if let choice = choice4 {
                                status(p: p4, choice: choice, width: geometry.size.width, option: 4)
                            }
                        }
                    })
                    .transition(.move(edge: .trailing))
                    .frame(height: CGFloat(total * 30 + total * 5 - 5))
                    .onAppear {
                        if p1 == 0.0 && p2 == 0.0 && p3 == 0.0 && p4 == 0.0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                                getPercents()
                            }
                        }
                    }
                } else {
                    VStack(spacing: 5){
                        voteButton(choice: choice1, num: 1)
                        voteButton(choice: choice2, num: 2)
                        if let choice = choice3 {
                            voteButton(choice: choice, num: 3)
                        }
                        if let choice = choice4 {
                            voteButton(choice: choice, num: 4)
                        }
                    }
                    .transition(.move(edge: .leading))
                }
            }
            let total: Int = count1 + count2 + (count3 ?? 0) + (count4 ?? 0)
            let singleExcp: String = (total == 1) ? "Vote" : "Votes"
            HStack {
                Text("\(total) \(singleExcp) - \(dateFinal)").font(.subheadline).foregroundStyle(.gray)
                Spacer()
            }
        }
        .padding(8)
        .background(content: {
            if !isGC {
                Color.gray.opacity(0.1)
            }
        })
        .overlay(content: {
            if !isGC {
                RoundedRectangle(cornerRadius: 10).stroke(.gray, lineWidth: 1)
            }
        })
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .sheet(isPresented: $showUserSheet, content: {
            userSheet()
                .presentationDragIndicator(.hidden)
                .presentationDetents([.medium, .large])
        })
        .onAppear {
            if !appeared {
                refreshData()
            }
            appeared = true
            if dateFinal == "0 days" {
                let timestamp = timestamp.dateValue()
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
                
                let timeDifference = Calendar.current.dateComponents([.year, .month, .weekOfYear, .day, .hour], from: timestamp, to: Date())
                
                if let years = timeDifference.year, years > 0 {
                    dateFinal = "\(years) year" + (years > 1 ? "s ago" : " ago")
                } else if let months = timeDifference.month, months > 0 {
                    dateFinal = "\(months) month" + (months > 1 ? "s ago" : " ago")
                } else if let weeks = timeDifference.weekOfYear, weeks > 0 {
                    dateFinal = "\(weeks) week" + (weeks > 1 ? "s ago" : " ago")
                } else if let days = timeDifference.day, days > 0 {
                    dateFinal = "\(days) day" + (days > 1 ? "s ago" : " ago")
                } else if let hours = timeDifference.hour, hours > 0 {
                    dateFinal = "\(hours) hour" + (hours > 1 ? "s ago" : " ago")
                } else {
                    dateFinal = "Less than an hour ago"
                }
            }
        }
        .onDisappear(perform: {
            appeared = false
        })
    }
    func refreshData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) {
            getPollDB { (result: ([String]?, Int?, Int?, Int?, Int?)) in
                let (strings, int1, int2, int3, int4) = result
                if (int1 ?? 0) > count1 || (int2 ?? 0) > count2 || (int3 ?? 0) > (count3 ?? 0) || (int4 ?? 0) > (count4 ?? 0) {
                    
                    whoVoted = strings ?? []
                    count1 = int1 ?? 0
                    count2 = int2 ?? 0
                    count3 = int3 ?? 0
                    count4 = int4 ?? 0
                    
                    getPercents()
                    
                    updateOriginal(votes: strings, c1: int1, c2: int2, c3: int3, c4: int4)
                    
                    if appeared {
                        refreshData()
                    }
                } else if appeared {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) {
                        refreshData()
                    }
                }
            }
        }
    }
    func updateOriginal(votes: [String]?, c1: Int?, c2: Int?, c3: Int?, c4: Int?) {
        if isGC {
            if let index = groupChat.chats.firstIndex(where: { $0.id == groupID }) {
                if let pos = groupChat.chats[index].messages?.firstIndex(where: { $0.id == messageID }) {
                    groupChat.chats[index].messages?[pos].count1 = c1
                    groupChat.chats[index].messages?[pos].count2 = c2
                    groupChat.chats[index].messages?[pos].count3 = c3
                    groupChat.chats[index].messages?[pos].count4 = c4
                    groupChat.chats[index].messages?[pos].voted = votes
                }
            }
        } else if isDevGroup {
            if let index = channelModel.groupsDev.firstIndex(where: { $0.id == groupID }) {
                if let pos = channelModel.groupsDev[index].messages?.firstIndex(where: {$0.id == messageID }) {
                    channelModel.groupsDev[index].messages?[pos].count1 = c1
                    channelModel.groupsDev[index].messages?[pos].count2 = c2
                    channelModel.groupsDev[index].messages?[pos].count3 = c3
                    channelModel.groupsDev[index].messages?[pos].count4 = c4
                    channelModel.groupsDev[index].messages?[pos].voted = votes
                }
            }
        } else {
            if let index = channelModel.groups.firstIndex(where: { $0.1.id == groupID }) {
                if let indexSec = channelModel.groups[index].1.messages?.firstIndex(where: { $0.id == channelModel.groups[index].0 }) {
                    if let indexThird = channelModel.groups[index].1.messages?[indexSec].messages.firstIndex(where: { $0.id == messageID }) {
                        channelModel.groups[index].1.messages?[indexSec].messages[indexThird].count1 = c1
                        channelModel.groups[index].1.messages?[indexSec].messages[indexThird].count2 = c2
                        channelModel.groups[index].1.messages?[indexSec].messages[indexThird].count3 = c3
                        channelModel.groups[index].1.messages?[indexSec].messages[indexThird].count4 = c4
                        channelModel.groups[index].1.messages?[indexSec].messages[indexThird].voted = votes
                    }
                }
            }
        }
    }
    func getPollDB(completion: @escaping(([String]?, Int?, Int?, Int?, Int?)) -> Void) {
        if !groupID.isEmpty && !messageID.isEmpty {
            if isGC {
                Firestore.firestore().collection("groupChats")
                    .document(groupID).collection("texts").document(messageID)
                    .getDocument { snapshot, _ in
                        if let snapshot = snapshot, let message = try? snapshot.data(as: GroupMessage.self) {
                            completion((message.voted, message.count1, message.count2, message.count3, message.count4))
                        } else {
                            completion((nil, nil, nil, nil, nil))
                        }
                    }
            } else if !squareName.isEmpty || isDevGroup {
                Firestore.firestore()
                    .collection(isDevGroup ? "Groups" : "userGroups")
                    .document(groupID).collection(isDevGroup ? "convo" : squareName)
                    .document(messageID)
                    .getDocument { snapshot, _ in
                        if let snapshot = snapshot, let message = try? snapshot.data(as: Tweet.self) {
                            completion((message.voted, message.count1, message.count2, message.count3, message.count4))
                        } else {
                            completion((nil, nil, nil, nil, nil))
                        }
                    }
            } else {
                completion((nil, nil, nil, nil, nil))
            }
        } else {
            completion((nil, nil, nil, nil, nil))
        }
    }
    func getPercents(){
        let total = Double(count1 + count2 + (count3 ?? 0) + (count4 ?? 0))
        
        withAnimation(.bouncy(duration: 0.25)){
            p1 = Double(count1) / total
            p2 = Double(count2) / total
            p3 = Double(count3 ?? 0) / total
            p4 = Double(count4 ?? 0) / total
        }
    }
    func status(p: Double, choice: String, width: CGFloat, option: Int) -> some View {
        Button(action: {
            whichOption = option
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            fetchAllUsers()
            showUserSheet = true
        }, label: {
            ZStack(alignment: .leading){
                UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8, bottomTrailingRadius: Int(p * 100.0) == 100 ? 8 : 0, topTrailingRadius: Int(p * 100.0) == 100 ? 8 : 0)
                    .foregroundStyle(.gray).opacity(colorScheme == .dark ? 0.5 : 0.3)
                    .frame(width: ((p * width) > 3.0) ? p * width : 3.0)
                HStack {
                    Text(choice).font(.system(size: 16)).lineLimit(1).minimumScaleFactor(0.7).truncationMode(.tail)
                    Spacer()
                    Text("\(Int(p * 100.0))%")
                }.padding(.horizontal, 10)
            }.frame(height: 30)
        })
    }
    func voteButton(choice: String, num: Int) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)){
                viewModel.votedPosts.append(messageID)
            }
            
            if var uid = auth.currentUser?.id {
                uid += "\(num)"
                whoVoted.append(uid)
            }
            
            if num == 1 {
                count1 += 1
            } else if num == 2 {
                count2 += 1
            } else if num == 3 {
                count3 = (count3 ?? 0) + 1
            } else {
                count4 = (count4 ?? 0) + 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                getPercents()
            }
            
            if isGC {
                if let index = groupChat.chats.firstIndex(where: { $0.id == groupID }) {
                    if let pos = groupChat.chats[index].messages?.firstIndex(where: { $0.id == messageID }) {
                        if num == 1 {
                            groupChat.chats[index].messages?[pos].count1 = 1 + (groupChat.chats[index].messages?[pos].count1 ?? 0)
                        } else if num == 2 {
                            groupChat.chats[index].messages?[pos].count2 = 1 + (groupChat.chats[index].messages?[pos].count2 ?? 0)
                        } else if num == 3 {
                            groupChat.chats[index].messages?[pos].count3 = 1 + (groupChat.chats[index].messages?[pos].count3 ?? 0)
                        } else {
                            groupChat.chats[index].messages?[pos].count4 = 1 + (groupChat.chats[index].messages?[pos].count4 ?? 0)
                        }
                    }
                }
                GroupChatService().votePoll(textID: messageID, groupID: groupID, count: num)
            } else {
                if isDevGroup {
                    if let index = channelModel.groupsDev.firstIndex(where: { $0.id == groupID }) {
                        if let pos = channelModel.groupsDev[index].messages?.firstIndex(where: {$0.id == messageID }) {
                            if num == 1 {
                                channelModel.groupsDev[index].messages?[pos].count1 = 1 + (channelModel.groupsDev[index].messages?[pos].count1 ?? 0)
                            } else if num == 2 {
                                channelModel.groupsDev[index].messages?[pos].count2 = 1 + (channelModel.groupsDev[index].messages?[pos].count2 ?? 0)
                            } else if num == 3 {
                                channelModel.groupsDev[index].messages?[pos].count3 = 1 + (channelModel.groupsDev[index].messages?[pos].count3 ?? 0)
                            } else {
                                channelModel.groupsDev[index].messages?[pos].count4 = 1 + (channelModel.groupsDev[index].messages?[pos].count4 ?? 0)
                            }
                        }
                    }
                } else {
                    if let index = channelModel.groups.firstIndex(where: { $0.1.id == groupID }) {
                        if let indexSec = channelModel.groups[index].1.messages?.firstIndex(where: { $0.id == channelModel.groups[index].0 }) {
                            if let indexThird = channelModel.groups[index].1.messages?[indexSec].messages.firstIndex(where: { $0.id == messageID }) {
                                if num == 1 {
                                    channelModel.groups[index].1.messages?[indexSec].messages[indexThird].count1 = 1 + (channelModel.groups[index].1.messages?[indexSec].messages[indexThird].count1 ?? 0)
                                } else if num == 2 {
                                    channelModel.groups[index].1.messages?[indexSec].messages[indexThird].count2 = 1 + (channelModel.groups[index].1.messages?[indexSec].messages[indexThird].count2 ?? 0)
                                } else if num == 3 {
                                    channelModel.groups[index].1.messages?[indexSec].messages[indexThird].count3 = 1 + (channelModel.groups[index].1.messages?[indexSec].messages[indexThird].count3 ?? 0)
                                } else {
                                    channelModel.groups[index].1.messages?[indexSec].messages[indexThird].count4 = 1 + (channelModel.groups[index].1.messages?[indexSec].messages[indexThird].count4 ?? 0)
                                }
                            }
                        }
                    }
                }
                ExploreService().votePoll(textID: messageID, groupID: groupID, square: squareName, devGroup: isDevGroup, count: num)
            }
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }, label: {
            Capsule()
                .stroke(.blue, lineWidth: 2)
                .frame(height: 26)
                .overlay {
                    Text(choice).font(.system(size: 16)).bold().foregroundStyle(.blue)
                        .lineLimit(1).minimumScaleFactor(0.7).truncationMode(.tail)
                }
        })
    }
    func userSheet() -> some View {
        VStack(spacing: 10){
            if whichOption == 1 {
                Text(choice1).font(.title3).bold()
            } else if whichOption == 2 {
                Text(choice2).font(.title3).bold()
            } else if whichOption == 3 {
                Text(choice3 ?? "").font(.title3).bold()
            } else {
                Text(choice4 ?? "").font(.title3).bold()
            }
            ScrollView {
                Color.clear.frame(height: 5)
                HStack {
                    Text("Voted").font(.subheadline).bold()
                    Spacer()
                    if fetchingUsers {
                        ProgressView()
                    }
                }
                LazyVStack(spacing: 10){
                    if !users.isEmpty {
                        ForEach(users) { user in
                            Button(action: {
                                selectedUser = user
                                showUserSheet = false
                                showUser = true
                            }, label: {
                                HStack {
                                    ZStack {
                                        personView(size: 41)
                                        if let image = user.profileImageUrl {
                                            KFImage(URL(string: image))
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 40, height: 40)
                                                .clipShape(Circle())
                                                .contentShape(Circle())
                                                .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                        }
                                    }.padding(.trailing, 5)
                                    VStack(alignment: .leading, spacing: 4){
                                        Text(user.fullname).font(.system(size: 16)).bold()
                                        Text("@\(user.username)").font(.system(size: 13))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.subheadline).padding(.trailing, 8)
                                }
                            })
                            if user != users.last {
                                Divider().padding(.leading, 55)
                            }
                        }
                    } else {
                        HStack {
                            Spacer()
                            Text("No one has voted here yet!").font(.headline)
                            Spacer()
                        }
                    }
                }
                .padding(8)
                .background(.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                Color.clear.frame(height: 50)
            }.scrollIndicators(.hidden)
        }
        .padding()
        .ignoresSafeArea(edges: .bottom)
    }
    func fetchAllUsers() {
        fetchingUsers = true
        let findSuffix = "\(whichOption)"
        users = []
        var toFind = whoVoted.filter { element in
            return element.hasSuffix(findSuffix)
        }
        toFind = Array(Set(toFind))
        
        if toFind.isEmpty {
            fetchingUsers = false
            return
        }

        var noneFound: Int = 0
        toFind.forEach { element in
            let user_id = String(element.dropLast(1))
            
            if let curr = auth.currentUser, user_id == curr.id {
                users.append(curr)
                if users.count == toFind.count {
                    fetchingUsers = false
                }
            } else if let user = popRoot.randomUsers.first(where: { $0.id == user_id }) {
                users.append(user)
                if users.count == toFind.count {
                    fetchingUsers = false
                }
            } else if let user = profile.users.first(where: { $0.user.id == user_id })?.user {
                users.append(user)
                if users.count == toFind.count {
                    fetchingUsers = false
                }
            } else if let index = groupChat.chats.firstIndex(where: { $0.id == groupID }), let user = groupChat.chats[index].users?.first(where: { $0.id == user_id }) {
                users.append(user)
                if users.count == toFind.count {
                    fetchingUsers = false
                }
            } else if let user = messageModel.chats.first(where: { $0.user.id == user_id })?.user {
                users.append(user)
                if users.count == toFind.count {
                    fetchingUsers = false
                }
            } else if let index = channelModel.groups.firstIndex(where: { $0.1.id == groupID }), let user = channelModel.groups[index].1.users?.first(where: { $0.id == user_id }) {
                users.append(user)
                if users.count == toFind.count {
                    fetchingUsers = false
                }
            } else {
                UserService().fetchSafeUser(withUid: user_id) { optional_user in
                    if let user = optional_user {
                        users.append(user)
                        popRoot.randomUsers.append(user)
                    } else {
                        noneFound += 1
                    }
                    if (users.count + noneFound) >= toFind.count {
                        fetchingUsers = false
                    }
                }
            }
        }
    }
}

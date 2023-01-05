import SwiftUI
import MapKit
import Firebase

struct searchLoc: Identifiable, Hashable, Equatable {
    var id: String = UUID().uuidString
    var searchName: String
    var lat: Double
    var long: Double
}

struct SendLocationView: View {
    @EnvironmentObject var globe: GlobeViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @State var isSearching = false
    @State var text = ""
    let manager = GlobeLocationManager()
    @EnvironmentObject var searchModel: AddressSearchViewModel
    @EnvironmentObject var message: MessageViewModel
    @EnvironmentObject var groupChat: GroupChatViewModel
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                if isSearching {
                    VStack(spacing: 15){
                        ForEach(searchModel.searchResults) { element in
                            Button(action: {
                                sendRandomLocation(lat: element.lat, long: element.long, name: element.searchName)
                            }, label: {
                                HStack(spacing: 15){
                                    Image(systemName: "magnifyingglass")
                                    Text(element.searchName).lineLimit(1).truncationMode(.tail)
                                    Spacer()
                                }.font(.headline)
                            })
                            if element != searchModel.searchResults.last {
                                Divider()
                            }
                        }
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeIn(duration: 0.3), value: isSearching)
                    .padding()
                } else {
                    VStack(spacing: 20){
                        if let loc = globe.currentLocation {
                            let startPosition = MapCameraPosition.region (
                                MKCoordinateRegion (
                                    center: CLLocationCoordinate2D(latitude: loc.lat, longitude: loc.long),
                                    span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
                                )
                            )
                            
                            Map(initialPosition: startPosition) {
                                UserAnnotation()
                                    .tint(.blue)
                                    .stroke(.blue)
                                    .foregroundStyle(.blue)
                            }.frame(height: 400)
                        } else {
                            Map() {
                                UserAnnotation()
                                    .tint(.blue)
                                    .stroke(.blue)
                                    .foregroundStyle(.blue)
                            }.frame(height: 400)
                        }
                        
                        if globe.currentLocation != nil {
                            Button(action: {
                                sendCurrentLocation()
                            }, label: {
                                HStack(spacing: 15){
                                    Image(systemName: "location.viewfinder")
                                        .font(.title)
                                    VStack(alignment: .leading, spacing: 3){
                                        Text("Send Your Current Location")
                                            .fontWeight(.medium).font(.headline)
                                        Text("Accurate to 10m")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .foregroundStyle(.green)
                                .background(.gray.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal)
                            })
                        }
                        
                        if !searchModel.searchResults.isEmpty {
                            VStack(spacing: 5){
                                HStack {
                                    Text("Search Results")
                                        .fontWeight(.medium)
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                VStack(spacing: 10){
                                    ForEach(searchModel.searchResults) { element in
                                        Button {
                                            sendRandomLocation(lat: element.lat, long: element.long, name: element.searchName)
                                        } label: {
                                            HStack(spacing: 15){
                                                Image(systemName: "mappin.and.ellipse")
                                                    .font(.subheadline)
                                                    .padding(8)
                                                    .background(.gray.opacity(0.4))
                                                    .clipShape(Circle())
                                                Text(element.searchName)
                                                    .font(.headline).fontWeight(.semibold)
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(.gray.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal)
                            }
                        }
                        
                        VStack(spacing: 5){
                            HStack {
                                Text("Popular Places")
                                    .fontWeight(.medium)
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)
                            VStack(spacing: 10){
                                ForEach(CitySearchViewModel().popularCities) { element in
                                    Button {
                                        sendRandomLocation(lat: element.latitude, long: element.longitude, name: "\(element.city), \(element.country)")
                                    } label: {
                                        HStack(spacing: 15){
                                            Image(systemName: "mappin.and.ellipse")
                                                .font(.subheadline)
                                                .padding(8)
                                                .background(.gray.opacity(0.4))
                                                .clipShape(Circle())
                                            Text("\(element.city), \(element.country)")
                                                .font(.headline).fontWeight(.semibold)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)
                        }
                        Color.clear.frame(height: 70)
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeIn(duration: 0.15), value: isSearching)
                }
            }
            .searchable(text: $text, isPresented: $isSearching, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("Search or enter and address"))
            .onSubmit(of: .search) {
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !searchModel.searchResults.contains(where: { $0.searchName == text }) {
                    searchModel.performSearch(queryStr: text)
                }
            }
            .onChange(of: text, { _, _ in
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    sortSearch()
                }
            })
            .scrollIndicators(.hidden)
            .presentationDragIndicator(.hidden)
            .navigationTitle("Send Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Cancel").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline)
                    })
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if searchModel.searching {
                        ProgressView().scaleEffect(1.2)
                    } else {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }, label: {
                            Image(systemName: "arrow.clockwise").foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline)
                        })
                    }
                }
            })
        }
        .onAppear {
            if globe.currentLocation == nil {
                manager.requestLocation() { place in
                    if !place.0.isEmpty && !place.1.isEmpty {
                        globe.currentLocation = myLoc(country: place.1, state: place.4, city: place.0, lat: place.2, long: place.3)
                    }
                }
            }
        }
        .onChange(of: searchModel.searchResults) { _, _ in
            sortSearch()
        }
    }
    func sendCurrentLocation() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let current = globe.currentLocation {
            let name = "\(auth.currentUser?.username ?? "") Current Location"
            if message.currentChat != nil {
                sendMessage(lat: current.lat, long: current.long, name: name)
            } else if groupChat.currentChat != nil {
                sendGC(lat: current.lat, long: current.long, name: name)
            }
        }
        presentationMode.wrappedValue.dismiss()
    }
    func sendRandomLocation(lat: Double, long: Double, name: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if message.currentChat != nil {
            sendMessage(lat: lat, long: long, name: name)
        } else if groupChat.currentChat != nil {
            sendGC(lat: lat, long: long, name: name)
        }
        presentationMode.wrappedValue.dismiss()
    }
    func sendMessage(lat: Double, long: Double, name: String) {
        if let index = message.currentChat {
            let uid = Auth.auth().currentUser?.uid ?? ""
            let uid_prefix = String(uid.prefix(5))
            let id = uid_prefix + String("\(UUID())".prefix(15))
            
            let new = Message(id: id, uid_one_did_recieve: (message.chats[index].convo.uid_one == auth.currentUser?.id ?? "") ? false : true, seen_by_reciever: false, text: nil, imageUrl: nil, timestamp: Timestamp(), sentAImage: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyELO: nil, replyFile: nil, videoURL: nil, lat: lat, long: long, name: name)
            
            message.sendStory(i: index, myMessArr: auth.currentUser?.myMessages ?? [], otherUserUid: message.chats[index].user.id ?? "", caption: "", imageUrl: nil, videoUrl: nil, messageID: id, audioStr: nil, lat: lat, long: long, name: name, pinmap: nil)
            
            message.chats[index].lastM = new
            
            if message.chats[index].messages != nil {
                message.chats[index].messages?.insert(new, at: 0)
                message.setDate()
            } else {
                message.chats[index].messages = [new]
                message.setDate()
            }
        }
    }
    func sendGC(lat: Double, long: Double, name: String) {
        if let index = groupChat.currentChat, let docID = groupChat.chats[index].id {
            let id = String((auth.currentUser?.id ?? "").prefix(6)) + String("\(UUID())".prefix(10))
            
            let new = GroupMessage(id: id, seen: nil, text: nil, imageUrl: nil, audioURL: nil, videoURL: nil, file: nil, replyFrom: nil, replyText: nil, replyImage: nil, replyFile: nil, replyAudio: nil, replyVideo: nil, countSmile: nil, countCry: nil, countThumb: nil, countBless: nil, countHeart: nil, countQuestion: nil, timestamp: Timestamp(), lat: lat, long: long, name: name)
            
            GroupChatService().sendMessage(docID: docID, text: "", imageUrl: nil, messageID: id, replyFrom: nil, replyText: nil, replyImage: nil, replyVideo: nil, replyAudio: nil, replyFile: nil, videoURL: nil, audioURL: nil, fileURL: nil, exception: false, lat: lat, long: long, name: name, choice1: nil, choice2: nil, choice3: nil, choice4: nil, pinmap: nil)
            
            groupChat.chats[index].lastM = new
            
            if groupChat.chats[index].messages != nil {
                groupChat.chats[index].messages?.insert(new, at: 0)
                groupChat.setDate()
            } else {
                groupChat.chats[index].messages = [new]
                groupChat.setDate()
            }
        }
    }
    func sortSearch() {
        searchModel.searchResults = searchModel.searchResults.sorted { loc1, loc2 in
            let distance1 = levenshtein(loc1.searchName, text)
            let distance2 = levenshtein(loc2.searchName, text)
            return distance1 < distance2
        }
    }
}

func levenshtein(_ lhs: String, _ rhs: String) -> Int {
    let lhsChars = Array(lhs)
    let rhsChars = Array(rhs)
    let lhsLength = lhsChars.count
    let rhsLength = rhsChars.count
    var distance = Array(repeating: Array(repeating: 0, count: rhsLength + 1), count: lhsLength + 1)
    for i in 0...lhsLength {
        distance[i][0] = i
    }
    for j in 0...rhsLength {
        distance[0][j] = j
    }
    for i in 1...lhsLength {
        for j in 1...rhsLength {
            if lhsChars[i - 1] == rhsChars[j - 1] {
                distance[i][j] = distance[i - 1][j - 1]
            } else {
                let delete = distance[i - 1][j] + 1
                let insert = distance[i][j - 1] + 1
                let substitute = distance[i - 1][j - 1] + 1
                distance[i][j] = min(delete, min(insert, substitute))
            }
        }
    }
    return distance[lhsLength][rhsLength]
}

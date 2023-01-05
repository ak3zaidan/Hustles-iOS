import SwiftUI
import CoreLocation
import Kingfisher

struct YelpRowView: View {
    @EnvironmentObject var group: GroupChatViewModel
    @EnvironmentObject var message: MessageViewModel
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var globe: GlobeViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var vm: LocationsViewModel
    let daysMap = [
        0: "Sunday",
        1: "Monday",
        2: "Tuesday",
        3: "Wednesday",
        4: "Thursday",
        5: "Friday",
        6: "Saturday"
    ]
    @Environment(\.colorScheme) var colorScheme
    let placeID: String
    let isChat: Bool
    let isGroup: Bool
    let otherPhoto: String?
    @State var business: mainBusiness? = nil
    @State var showHours = false
    @State var showDirections = false
    @State var error = false
    @State var currentImage = 0
    @State var changeImage = 0
    @State var distanceThem = 0.0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showForward = false
    @State var sendLink: String = ""
    //upload hustle
    @State private var showNewTweetView = false
    @State var uploadVisibility: String = ""
    @State var visImage: String = ""
    @State var initialContent: uploadContent? = nil
    @State var place: myLoc? = nil
    
    var body: some View {
        VStack(spacing: 3){
            if let business = self.business {
                let photo: [String] = business.business.image_url == nil ? [] : [business.business.image_url ?? ""]
                let images: [String] = business.business.photos ?? [] + photo
                HStack(spacing: 4){
                    NavigationLink {
                        SinglePlaceSheetView(show: .constant(false), place: business) {
                            let pinName = "\(business.business.name ?? ""),\(business.coordinates.latitude),\(business.coordinates.longitude)"
                            
                            if (auth.currentUser?.mapPins ?? []).contains(pinName) {
                                popRoot.alertReason = "Pin Already Added"
                                popRoot.alertImage = "exclamationmark.triangle.fill"
                                withAnimation(.easeInOut(duration: 0.2)){
                                    popRoot.showAlert = true
                                }
                            } else {
                                UserService().addPinForUser(name: business.business.name ?? "", lat: business.coordinates.latitude, long: business.coordinates.longitude)
                                if auth.currentUser?.mapPins == nil {
                                    auth.currentUser?.mapPins = [pinName]
                                } else {
                                    auth.currentUser?.mapPins?.append(pinName)
                                }
                                popRoot.alertReason = "Pin dropped"
                                popRoot.alertImage = "checkmark.seal"
                                withAnimation(.easeInOut(duration: 0.2)){
                                    popRoot.showAlert = true
                                }
                            }
                        }
                        .navigationBarBackButtonHidden()
                    } label: {
                        Text(business.business.name ?? "")
                            .font(.title3).bold().lineLimit(1).minimumScaleFactor(0.8)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                    Spacer()
                    Menu {
                        if let id = business.business.id {
                            Button(action: {
                                showDirections = true
                            }, label: {
                                Label("Directions", systemImage: "car.fill")
                            })
                            Button(action: {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                callNumber(phoneNumber: business.business.phone ?? "")
                            }, label: {
                                Label("Call", systemImage: "phone.fill")
                            })
                            Button(action: {
                                sendLink = "https://hustle.page/yelp/\(id)/"
                                showForward = true
                            }, label: {
                                Label("Share", systemImage: "paperplane.fill")
                            })
                            Button(action: {
                                showNewTweetView = true
                            }, label: {
                                Label("Post", systemImage: "plus")
                            })
                            Button(action: {
                                popRoot.alertReason = "Place URL copied"
                                popRoot.alertImage = "link"
                                withAnimation {
                                    popRoot.showAlert = true
                                }
                                UIPasteboard.general.string = "https://hustle.page/yelp/\(id)/"
                            }, label: {
                                Label("Copy Link", systemImage: "link")
                            })
                        }
                    } label: {
                        ZStack {
                            Rectangle()
                                .frame(width: 30, height: 15)
                                .foregroundStyle(.gray).opacity(0.001)
                            Image(systemName: "ellipsis")
                                .foregroundStyle(.blue)
                                .font(.title3).bold()
                        }
                    }
                }
                HStack(spacing: 4){
                    Image(getYelpImage(rating: business.business.rating ?? 0.0))
                    Text("\(business.business.review_count ?? 0) Ratings")
                        .font(.caption)
                    Spacer()
                }
                HStack(spacing: 4){
                    Text(getFirstThreeUniqueAliasesOrTitles(categories: business.business.categories))
                        .lineLimit(1).font(.caption)
                    Text("-")
                    let t1 = String(repeating: "$", count: business.business.price?.count ?? 2)
                    let t2 = String(repeating: "$", count: 4 - t1.count)
                    HStack(spacing: 0.5){
                        Text(t1).font(.caption)
                        Text(t2).font(.caption).foregroundStyle(.gray)
                    }
                    Spacer()
                }
                HStack(spacing: 4){
                    let city = (business.business.location?.city ?? "") + ", " + (business.business.location?.state ?? "")
                    Text("\(String(format: "%.1f", business.distanceFromMe)) miles - \(city)")
                        .lineLimit(1).font(.caption)
                    Spacer()
                    Button(action: {
                        showHours = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }, label: {
                        if let hours = business.business.hours?.first {
                            let status = isCurrentlyOpen(hours: hours)
                            HStack(spacing: 2){
                                Text(status ? "Open" : "Closed")
                                Image(systemName: "info.circle")
                            }.font(.subheadline).foregroundStyle(status ? .green : .red).bold()
                        } else if let status = business.business.hours?.first?.is_open_now {
                            HStack(spacing: 2){
                                Text(status ? "Open" : "Closed")
                                Image(systemName: "info.circle")
                            }.font(.subheadline).foregroundStyle(status ? .green : .red).bold()
                        }
                    })
                }.padding(.bottom, 5)
                if !images.isEmpty {
                    KFImage(URL(string: images[currentImage]))
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .contentShape(RoundedRectangle(cornerRadius: 15))
                        .overlay(alignment: .bottomTrailing){
                            Button(action: {
                                if let url = URL(string: "https://www.yelp.com") {
                                    UIApplication.shared.open(url)
                                }
                            }, label: {
                                ZStack {
                                    Color.gray.opacity(0.001).frame(width: 50, height: 25)
                                    Image("yelpLogo")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 25, height: 25)
                                }
                                .padding(15)
                            })
                        }
                }
                if isChat || isGroup {
                    GeometryReader { geo in
                        HStack(spacing: 0){
                            ZStack {
                                personView(size: 40)
                                if let image = auth.currentUser?.profileImageUrl {
                                    KFImage(URL(string: image))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .contentShape(Circle())
                                }
                            }
                            Rectangle().frame(height: 2)
                                .foregroundStyle(.gray)
                                .overlay {
                                    Text(String(format: "%.1f", business.distanceFromMe) + "m")
                                        .font(.caption)
                                        .offset(y: 10)
                                }
                            CustomPinYelp(image: images.last ?? "").scaleEffect(0.8)
                            Rectangle().frame(height: 2)
                                .foregroundStyle(.gray)
                                .overlay {
                                    Text(String(format: "%.1f", distanceThem) + "m")
                                        .font(.caption)
                                        .offset(y: 10)
                                }
                            ZStack {
                                if isChat {
                                    personView(size: 40)
                                } else if isGroup {
                                    ZStack(alignment: .center){
                                        Circle()
                                            .fill(colorScheme == .dark ? Color(UIColor.darkGray).gradient : Color(UIColor.lightGray).gradient)
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "person.3.fill")
                                            .foregroundColor(.white).font(.headline)
                                    }
                                }
                                if let image = otherPhoto {
                                    KFImage(URL(string: image))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .contentShape(Circle())
                                }
                            }
                        }
                    }
                }
            } else if error {
                VStack(spacing: 7){
                    HStack {
                        Text("An Error Occured")
                            .font(.headline).bold()
                        Spacer()
                    }
                    HStack {
                        Text("Could not fetch Yelp location, check your network. This location may have been removed from Yelp.")
                            .font(.caption).multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
            } else {
                VStack(spacing: 5){
                    HStack {
                        RoundedRectangle(cornerRadius: 5)
                            .frame(width: 80, height: 10)
                            .foregroundStyle(.gray).opacity(0.6)
                        Spacer()
                    }
                    HStack {
                        RoundedRectangle(cornerRadius: 5)
                            .frame(width: 80, height: 10)
                            .foregroundStyle(.gray).opacity(0.6)
                        Spacer()
                    }
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(.gray).opacity(0.6)
                }
                .shimmering()
            }
        }
        .frame(height: error ? 85 : ((isChat || isGroup) && business != nil) ? 282 : 220)
        .frame(maxWidth: widthOrHeight(width: true) * 0.7)
        .padding(.horizontal, 10).padding(.vertical, 10)
        .background(.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .onAppear(perform: {
            var id = self.placeID
            if id.contains("http") {
                id = extractID(from: self.placeID) ?? ""
            }
            if !id.isEmpty {
                if let first = vm.allRestaurants.first(where: { $0.business.id == id }) {
                    self.business = first
                    theirDistance()
                } else {
                    var coords = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
                    if let place = globe.currentLocation {
                        coords.latitude = place.lat
                        coords.longitude = place.long
                    } else if let place = auth.currentUser?.currentLocation {
                        if let possible = extractLatLong(from: place) {
                            coords.latitude = possible.latitude
                            coords.longitude = possible.longitude
                        }
                    }
                    vm.getRestaurantDetailsYelpRowView(currentLoc: coords, id: id) { bus in
                        self.business = bus
                        if self.business == nil {
                            withAnimation(.easeInOut(duration: 0.2)){
                                self.error = true
                            }
                        }
                        theirDistance()
                    }
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)){
                    error = true
                }
            }
        })
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendLink)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
        })
        .fullScreenCover(isPresented: $showNewTweetView){
            NewTweetView(place: $place, visibility: $uploadVisibility, visibilityImage: $visImage, initialContent: $initialContent, yelpID: business?.business.id)
        }
        .sheet(isPresented: $showHours, content: {
            VStack(spacing: 10){
                HStack {
                    Text("Hours")
                        .foregroundStyle(.gray)
                        .font(.subheadline).fontWeight(.heavy)
                    Spacer()
                }.padding(.leading)
                Divider().overlay(Color.gray)
                if let place = business?.business {
                    if let hours = place.hours?.first, let open = hours.open {
                        VStack(spacing: 12){
                            ForEach(open, id: \.self) { element in
                                HStack(spacing: 3){
                                    Text(daysMap[element.day ?? 0] ?? "Monday")
                                    Spacer()
                                    let data = formatOpenTimes(open: element)
                                    Text(data.0).fontWeight(.medium)
                                    Text(data.1)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.gray)
                                    Text("-")
                                    Text(data.2).fontWeight(.medium)
                                    Text(data.3)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.gray)
                                }.font(.system(size: 16))
                            }
                        }
                    }
                }
            }
            .padding(8)
            .presentationDetents([.height(280)])
            .presentationCornerRadius(30.0)
        })
        .sheet(isPresented: $showDirections, content: {
            VStack(spacing: 10){
                HStack {
                    Text("Get There")
                        .foregroundStyle(.gray)
                        .font(.subheadline).fontWeight(.heavy)
                    Spacer()
                }.padding(.leading)
                Divider().overlay(Color.gray)
                if let place = business?.business {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)){
                            showDirections = false
                        }
                        openMaps(lat: business?.coordinates.latitude ?? 0.0, long: business?.coordinates.longitude ?? 0.0, name: place.name ?? "")
                    }, label: {
                        HStack {
                            Image("appleMaps")
                                .resizable()
                                .scaledToFill().scaleEffect(1.7)
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .offset(y: 3)
                            Text("Open in Apple Maps").fontWeight(.regular)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline)
                    })
                    Divider().overlay(Color.gray)
                    if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)){
                                showDirections = false
                            }
                            if let url = URL(string: "comgooglemaps-x-callback://?saddr=&daddr=\(business?.coordinates.latitude ?? 0.0),\(business?.coordinates.longitude ?? 0.0)&directionsmode=driving") {
                                UIApplication.shared.open(url, options: [:])
                            }
                        }, label: {
                            HStack {
                                Image("googleMaps")
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(0.7)
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(lineWidth: 1.0)
                                            .opacity(0.3)
                                    }
                                Text("Open in Google Maps").fontWeight(.regular)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline)
                        })
                        Divider().overlay(Color.gray)
                    }
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)){
                            showDirections = false
                        }
                        if let addy = place.location {
                            UIPasteboard.general.string = constructAddress(from: addy)
                        }
                    }, label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .frame(width: 40, height: 40)
                                .background(.gray.opacity(colorScheme == .dark ? 0.3 : 0.13))
                                .clipShape(RoundedRectangle(cornerRadius: 12.0))
                            VStack(alignment: .leading, spacing: 2){
                                Text("Copy Address").fontWeight(.regular)
                                if let addy = place.location {
                                    Text(constructAddress(from: addy))
                                        .font(.system(size: 13)).foregroundStyle(.gray)
                                        .multilineTextAlignment(.leading)
                                }
                            }.padding(.trailing, 13)
                            Spacer()
                        }
                        .foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline)
                    })
                }
                Spacer()
            }
            .padding(8).padding(.top)
            .presentationDetents([.height(220)])
            .presentationCornerRadius(30.0)
        })
        .onReceive(timer, perform: { _ in
            if let business {
                changeImage += 1
                if changeImage == 3 {
                    changeImage = 0
                    let photo: [String] = business.business.image_url == nil ? [] : [business.business.image_url ?? ""]
                    let images: [String] = business.business.photos ?? [] + photo
                    
                    if images.count > 1 {
                        withAnimation(.easeInOut(duration: 0.2)){
                            if (currentImage + 1) < images.count {
                                currentImage += 1
                            } else {
                                currentImage = 0
                            }
                        }
                    }
                }
            }
        })
    }
    func theirDistance() {
        if let loc = business?.coordinates, isChat || isGroup {
            let pos1 = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
            var userPos: [CLLocation] = []
            
            if let index = message.currentChat {
                if let userLocStr = message.chats[index].user.currentLocation, let userLoc = extractLatLong(from: userLocStr) {
                    userPos.append(CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude))
                }
            } else if let index = group.currentChat, let users = group.chats[index].users {
                let allLocStrs = users.compactMap({ $0.currentLocation })
                allLocStrs.forEach { single in
                    if let final = extractLatLong(from: single) {
                        userPos.append(CLLocation(latitude: final.latitude, longitude: final.longitude))
                    }
                }
            }
            if !userPos.isEmpty {
                let avgLatitude = userPos.map { $0.coordinate.latitude }.reduce(0, +) / Double(userPos.count)
                let avgLongitude = userPos.map { $0.coordinate.longitude }.reduce(0, +) / Double(userPos.count)
                let avgLocation = CLLocation(latitude: avgLatitude, longitude: avgLongitude)
                let distanceInMeters = pos1.distance(from: avgLocation)
                self.distanceThem = distanceInMeters / 1609.34
            }
        }
    }
    func extractID(from urlString: String) -> String? {
        let components = urlString.components(separatedBy: "/")

        if let index = components.firstIndex(of: "yelp"), index + 1 < components.count {
            return components[index + 1]
        }
        
        return nil
    }
}

struct CustomPinYelp: View {
    let image: String
    @State var show: Bool = false
    @State var scale = 0.0
    @State var scaleInit = 0.0
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Image(systemName: "drop.fill")
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(y: 0.75)
                    .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                    .frame(width: 45, height: 45)
                    .rotationEffect(.degrees(180.0))
                
                KFImage(URL(string: image))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
                    .offset(y: -5)
            }
            .opacity(show ? 1.0 : 0.0)
            .scaleEffect(scale)
            Circle().frame(width: 6)
                .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255)).scaleEffect(scaleInit)
        }
        .onAppear {
            withAnimation(.smooth(duration: 0.3, extraBounce: 0.6)){
                scaleInit = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                show = true
                withAnimation(.smooth(duration: 0.3, extraBounce: 0.6)){
                    scale = 1.0
                }
            }
        }
        .onDisappear(perform: {
            show = false
            scale = 0.0
            scaleInit = 0.0
        })
    }
}

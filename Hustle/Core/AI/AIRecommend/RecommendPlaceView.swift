import SwiftUI
import CoreLocation
import Kingfisher

struct RecommendPlaceView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var globe: GlobeViewModel
    @EnvironmentObject var popRoot: PopToRoot
    @EnvironmentObject var vm: LocationsViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State var error = 0
    @State var showHours = false
    @State var showAddress = false
    @Namespace private var animation
    @State var currentIndex: Int = 0
    @State var generating = false
    @State var text = ""
    @State private var isExpanded: Bool = false
    @State private var expandedID: String?
    @State var selectedOption = ""
    @State private var showForward = false
    @State var sendLink: String = ""
    @State private var moveToIndex = 0
    let allPlaceOptions: [String] = ["Food", "Parks", "Cafe", "Hikes", "Smoothie", "Breakfast", "Steak", "Burgers", "Pizza", "Mexican Food", "Asian Food", "Thai Food", "Mediterranean Food", "Viewpoints", "Dinner", "Coffee", "Boba", "Gyms", "Pools", "Dessert"]
    let daysMap = [
        0: "Sunday",
        1: "Monday",
        2: "Tuesday",
        3: "Wednesday",
        4: "Thursday",
        5: "Friday",
        6: "Saturday"
    ]
    
    var body: some View {
        VStack {
            let all: [mainBusiness] = vm.allRestaurants.filter { element in
                return element.tag.lowercased() == selectedOption.lowercased()
            }
            
            header().padding(.top, 20)
            Spacer()
            if selectedOption.isEmpty || (!generating && vm.allRestaurants.isEmpty) {
                placeOptions()
                    .transition(.scale.combined(with: .opacity))
            } else if generating && all.isEmpty {
                LottieView(loopMode: .loop, name: "aiLoad")
                    .scaleEffect(0.8)
                    .frame(width: 100, height: 100)
                    .transition(.scale.combined(with: .opacity))
            } else {
                centerPlaces()
                    .transition(.scale.combined(with: .opacity))
            }
            Spacer()
            BottomOptions()
        }
        .presentationDetents([.fraction(0.99)])
        .presentationCornerRadius(20)
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendLink)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
        })
        .onChange(of: vm.gotData, { _, _ in
            withAnimation(.easeInOut(duration: 0.2)){
                generating = false
            }
            let all: [mainBusiness] = vm.allRestaurants.filter { element in
                return element.tag.lowercased() == selectedOption.lowercased()
            }
            
            if all.isEmpty {
                withAnimation(.easeInOut(duration: 0.2)){
                    error = 2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                    withAnimation(.easeInOut(duration: 0.15)){
                        error = 0
                    }
                }
            } else {
                getInitialData()
            }
        })
        .onChange(of: vm.recommendError, { _, _ in
            withAnimation(.easeInOut(duration: 0.2)){
                error = 1
                generating = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                withAnimation(.easeInOut(duration: 0.15)){
                    error = 0
                }
            }
        })
        .onChange(of: currentIndex, { _, _ in
            let all: [mainBusiness] = vm.allRestaurants.filter { element in
                return element.tag.lowercased() == selectedOption.lowercased()
            }
            
            if currentIndex < all.count {
                for i in currentIndex..<all.count {
                    if i > (currentIndex + 3) {
                        break
                    }
                    if let id = all[i].business.id, all[i].business.hours == nil && all[i].business.photos == nil {
                        vm.getRestaurantDetails(id: id)
                    }
                }
            }
        })
        .background {
            ZStack {
                LinearGradient(colors: [Color(red: 25 / 255, green: 176 / 255, blue: 255 / 255), .blue, .blue, .purple], startPoint: .bottomLeading, endPoint: .topTrailing)
                TransparentBlurView(removeAllFilters: true)
                    .blur(radius: 14, opaque: true)
                    .background(.black).opacity(0.45)
            }.ignoresSafeArea()
        }
        .overlay {
            if showAddress || showHours || isExpanded {
                TransparentBlurView(removeAllFilters: true)
                    .blur(radius: 10, opaque: true)
                    .background(.gray.opacity(0.4))
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)){
                            showHours = false
                            showAddress = false
                            isExpanded = false
                            expandedID = nil
                        }
                    }
            }
        }
        .overlay {
            let all: [mainBusiness] = vm.allRestaurants.filter { element in
                return element.tag.lowercased() == selectedOption.lowercased()
            }
            
            if !selectedOption.isEmpty && !all.isEmpty {
                VStack {
                    Spacer()
                    HStack(spacing: 30){
                        Button(action: {
                            if currentIndex < all.count {
                                if let phone = all[currentIndex].business.phone, !phone.isEmpty {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    callNumber(phoneNumber: phone)
                                }
                            }
                        }, label: {
                            Image(systemName: "phone.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background {
                                    TransparentBlurView(removeAllFilters: true)
                                        .blur(radius: 14, opaque: true)
                                        .background(.white).opacity(0.18)
                                }
                                .clipShape(Capsule())
                        })
                        Button(action: {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            withAnimation(.easeInOut(duration: 0.2)){
                                showAddress = true
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }, label: {
                            Image(systemName: "car.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background {
                                    TransparentBlurView(removeAllFilters: true)
                                        .blur(radius: 14, opaque: true)
                                        .background(.white).opacity(0.18)
                                }
                                .clipShape(Capsule())
                        })
                        Button(action: {
                            if currentIndex < all.count {
                                if let id = all[currentIndex].business.id, !id.isEmpty {
                                    sendLink = "https://hustle.page/yelp/\(id)/"
                                    showForward = true
                                }
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }, label: {
                            Image(systemName: "paperplane.fill")
                                .rotationEffect(.degrees(45.0))
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background {
                                    TransparentBlurView(removeAllFilters: true)
                                        .blur(radius: 14, opaque: true)
                                        .background(.white).opacity(0.18)
                                }
                                .clipShape(Capsule())
                        })
                    }
                    .offset(y: expandedID == nil ? widthOrHeight(width: true) * -0.7 : -10)
                    if expandedID == nil {
                        Spacer()
                    }
                }.transition(.scale.combined(with: .opacity))
            }
        }
        .overlay {
            if let expandedID, isExpanded {
                VStack(spacing: 15){
                    HStack {
                        Spacer()
                        Button {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.7, blendDuration: 0.7)) {
                                isExpanded = false
                                self.expandedID = nil
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline)
                                .padding(.horizontal, 10).frame(height: 35)
                                .background {
                                    TransparentBlurView(removeAllFilters: true)
                                        .blur(radius: 14, opaque: true)
                                        .background(.white).opacity(0.18)
                                }
                                .clipShape(Circle())
                        }
                    }.padding(.trailing)
                    DetailsViewPlace(image: expandedID, isExpanded: $isExpanded, animationID: animation, selected: $expandedID)
                        .padding(.horizontal)
                        .padding(.bottom, 72)
                }.padding(.top, 15)
            }
        }
        .overlay {
            if error != 0 {
                VStack {
                    HStack(spacing: 10){
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(error == 1 ? "An Error Occured" : "No Results Found").font(.headline).bold()
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)){
                            error = 0
                        }
                    }
                    .padding(.horizontal, 50)
                    Spacer()
                }.padding(.top, 60).transition(.move(edge: .top))
            }
        }
        .overlay(alignment: .bottom){
            if showHours {
                let all: [mainBusiness] = vm.allRestaurants.filter { element in
                    return element.tag.lowercased() == selectedOption.lowercased()
                }
                if currentIndex < all.count {
                    VStack {
                        VStack(spacing: 10){
                            HStack {
                                Text("Hours")
                                    .foregroundStyle(.gray)
                                    .font(.subheadline).fontWeight(.heavy)
                                Spacer()
                            }
                            Divider().overlay(Color.gray)
                            if let hours = all[currentIndex].business.hours?.first, let open = hours.open {
                                VStack(spacing: 8){
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
                        .padding(8)
                        .background(colorScheme == .dark ? .black : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                        
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)){
                                showHours = false
                            }
                        }, label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                Text("Done")
                                    .font(.headline)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline)
                            }
                            .frame(height: 40)
                            .padding(.bottom)
                        })
                    }
                    .padding(.horizontal, 10)
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .overlay(alignment: .bottom){
            if showAddress {
                let all: [mainBusiness] = vm.allRestaurants.filter { element in
                    return element.tag.lowercased() == selectedOption.lowercased()
                }
                if currentIndex < all.count {
                    VStack {
                        VStack(spacing: 10){
                            HStack {
                                Text("Get There")
                                    .foregroundStyle(.gray)
                                    .font(.subheadline).fontWeight(.heavy)
                                Spacer()
                            }
                            Divider().overlay(Color.gray)
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.2)){
                                    showAddress = false
                                }
                                openMaps(lat: all[currentIndex].coordinates.latitude, long: all[currentIndex].coordinates.longitude, name: all[currentIndex].business.name ?? "")
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
                                        showAddress = false
                                    }
                                    if let url = URL(string: "comgooglemaps-x-callback://?saddr=&daddr=\(all[currentIndex].coordinates.latitude),\(all[currentIndex].coordinates.longitude)&directionsmode=driving") {
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
                                    showAddress = false
                                }
                                if let addy = all[currentIndex].business.location {
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
                                        if let addy = all[currentIndex].business.location {
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
                        .padding(8)
                        .background(colorScheme == .dark ? .black : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                        
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)){
                                showAddress = false
                            }
                        }, label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                Text("Done")
                                    .font(.headline)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline)
                            }
                            .frame(height: 40)
                            .padding(.bottom)
                        })
                    }
                    .padding(.horizontal, 10)
                    .transition(.move(edge: .bottom))
                }
            }
        }
    }
    func getInitialData() {
        let all: [mainBusiness] = vm.allRestaurants.filter { element in
            return element.tag.lowercased() == selectedOption.lowercased()
        }
        
        let firstFew = Array(all.prefix(3))
        firstFew.forEach { element in
            if let id = element.business.id, element.business.hours == nil && element.business.photos == nil {
                vm.getRestaurantDetails(id: id)
            }
        }
    }
    @ViewBuilder
    func placeOptions() -> some View {
        ScrollView {
            TagLayout(alignment: .center, spacing: 12){
                ForEach(allPlaceOptions, id: \.self) { element in
                    Text(element)
                        .font(.subheadline).bold()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12).frame(height: 35)
                        .background {
                            TransparentBlurView(removeAllFilters: true)
                                .blur(radius: 14, opaque: true)
                                .background(.white).opacity(0.18)
                        }
                        .clipShape(Capsule())
                        .matchedGeometryEffect(id: element, in: animation)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)){
                                selectedOption = element
                                if !vm.allRestaurants.contains(where: { $0.tag == element }) {
                                    generating = true
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
                                    vm.loadRestraunts(currentLoc: coords, query: element)
                                }
                            }
                        }
                }
            }.padding(.top, widthOrHeight(width: true) * 0.45)
        }.scrollIndicators(.hidden).scrollDismissesKeyboard(.immediately)
    }
    @ViewBuilder
    func singlePlace(place: Business, distance: Double) -> some View {
        VStack {
            let photo: [String] = place.image_url == nil ? [] : [place.image_url ?? ""]
            let images: [String] = place.photos ?? [] + photo
            if let first = images.first, images.count == 1 {
                if expandedID == nil || (expandedID ?? "") != first {
                    CardViewPlace(image: first, isExpanded: $isExpanded, animationID: animation, isDetailsView: false, offset: .constant(.zero))
                        .frame(width: 236, height: 145)
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.8)) {
                                expandedID = first
                                isExpanded = true
                            }
                        }
                        .padding(.top, 3)
                } else {
                    Color.gray.opacity(0.001)
                        .frame(width: 240, height: 145).padding(.top, 3)
                }
            } else if images.count >= 2 {
                HStack(spacing: 3){
                    if expandedID == nil || (expandedID ?? "") != images[0] {
                        CardViewPlace(image: images[0], isExpanded: $isExpanded, animationID: animation, isDetailsView: false, offset: .constant(.zero))
                            .frame(width: 118, height: 145)
                            .onTapGesture {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.8)) {
                                    expandedID = images[0]
                                    isExpanded = true
                                }
                            }
                    } else {
                        Color.gray.opacity(0.001)
                            .frame(width: 118, height: 145)
                    }
                    if expandedID == nil || (expandedID ?? "") != images[1] {
                        CardViewPlace(image: images[1], isExpanded: $isExpanded, animationID: animation, isDetailsView: false, offset: .constant(.zero))
                            .frame(width: 118, height: 145)
                            .onTapGesture {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.8)) {
                                    expandedID = images[1]
                                    isExpanded = true
                                }
                            }
                    } else {
                        Color.gray.opacity(0.001)
                            .frame(width: 118, height: 145)
                    }
                }.padding(.top, 3)
            }
            HStack {
                Text(place.name ?? "-------")
                    .fontWeight(.semibold).minimumScaleFactor(0.8)
                    .lineLimit(1).font(.title3).foregroundStyle(.white)
                Spacer()
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
                    }.padding(.trailing, 15)
                })
            }.padding(.leading, 10).padding(.top, images.isEmpty ? 10 : 0)
            HStack(spacing: 4){
                Text(getFirstThreeUniqueAliasesOrTitles(categories: place.categories))
                    .lineLimit(1).font(.caption).foregroundStyle(.white)
                Text("-")
                let t1 = String(repeating: "$", count: place.price?.count ?? 2)
                let t2 = String(repeating: "$", count: 4 - t1.count)
                HStack(spacing: 0.5){
                    Text(t1).foregroundStyle(.white).font(.caption)
                    Text(t2).font(.caption).foregroundStyle(.gray)
                }
                Spacer()
            }
            .padding(.leading, 10)
            HStack {
                let city = (place.location?.city ?? "") + ", " + (place.location?.state ?? "")
                Text("\(String(format: "%.1f", distance)) miles - \(city)")
                    .lineLimit(1).font(.caption).foregroundStyle(.white)
                Spacer()
            }.padding(.leading, 10)
            Spacer()
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)){
                        showHours = true
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label: {
                    if let hours = place.hours?.first {
                        let status = isCurrentlyOpen(hours: hours)
                        HStack(spacing: 2){
                            Text(status ? "Open" : "Closed")
                            Image(systemName: "info.circle")
                        }
                        .font(.subheadline).foregroundStyle(status ? .green : .red).bold()
                        .brightness(status ? 0.2 : -0.2)
                    } else if let status = place.hours?.first?.is_open_now {
                        HStack(spacing: 2){
                            Text(status ? "Open" : "Closed")
                            Image(systemName: "info.circle")
                        }
                        .font(.subheadline).foregroundStyle(status ? .green : .red).bold()
                        .brightness(status ? 0.2 : -0.2)
                    }
                })
                Spacer()
                VStack(alignment: .trailing, spacing: 3){
                    Image(getYelpImage(rating: place.rating ?? 0.0))
                    Text("\(place.review_count ?? 0) Ratings")
                        .font(.caption)
                }
            }.padding(.horizontal, 10).padding(.bottom, 10)
        }
        .frame(width: 245, height: 285)
        .background((Color(red: 25 / 255, green: 176 / 255, blue: 255 / 255)))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(alignment: .topTrailing) {
            if place.image_url != nil || place.photos != nil {
                HStack(spacing: 4){
                    Image(systemName: "hand.thumbsup.fill")
                        .foregroundStyle(.yellow).rotationEffect(.degrees(-20.0))
                    Text(String(format: "%.1f", place.rating ?? 0.0))
                        .font(.subheadline)
                }
                .padding(5)
                .background(.gray)
                .clipShape(Capsule())
                .padding(8)
            }
        }
    }
    @ViewBuilder
    func centerPlaces() -> some View {
        VStack {
            let all: [mainBusiness] = vm.allRestaurants.filter { element in
                return element.tag.lowercased() == selectedOption.lowercased()
            }
            if let first = all.first, all.count == 1 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        singlePlace(place: first.business, distance: first.distanceFromMe)
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                SnapCarousel(trailingSpace: 110, index: $currentIndex, moveToIndex: $moveToIndex, items: all) { post in
                    GeometryReader { proxy in
                        let size = proxy.size
                        let index = all.firstIndex(where: { $0.id == post.id }) ?? 0
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                singlePlace(place: all[index].business, distance: all[index].distanceFromMe)
                                Spacer()
                            }
                            .frame(width: size.width)
                            .opacity(index == currentIndex ? 1.0 : 0.5)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder
    func BottomOptions() -> some View {
        VStack(spacing: 6){
            if !selectedOption.isEmpty {
                HStack(spacing: 10){
                    Spacer()
                    Text(selectedOption)
                        .font(.subheadline).bold()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12).frame(height: 35)
                        .background {
                            TransparentBlurView(removeAllFilters: true)
                                .blur(radius: 14, opaque: true)
                                .background(.white).opacity(0.18)
                        }
                        .clipShape(Capsule())
                        .matchedGeometryEffect(id: selectedOption, in: animation)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)){
                            selectedOption = ""
                            generating = false
                            currentIndex = 0
                            moveToIndex = 0
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }, label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .padding(.horizontal, 10).frame(height: 35)
                            .background {
                                TransparentBlurView(removeAllFilters: true)
                                    .blur(radius: 14, opaque: true)
                                    .background(.white).opacity(0.18)
                            }
                            .clipShape(Circle())
                    }).transition(.scale.combined(with: .opacity))
                }.frame(height: 45).padding(.trailing, 15)
            }
            TextField("", text: $text)
                .foregroundStyle(.white)
                .padding(.leading).padding(.trailing, 60).tint(.green)
                .frame(height: 40)
                .background {
                    ZStack {
                        TransparentBlurView(removeAllFilters: true)
                            .blur(radius: 14, opaque: true)
                            .background(.white).opacity(0.18)
                        if text.isEmpty {
                            HStack {
                                Text("Try 'Smoothies'")
                                    .foregroundStyle(.white)
                                    .fontWeight(.light)
                                    .opacity(0.7)
                                    .padding(.leading).padding(.leading, 1)
                                Spacer()
                            }
                        }
                    }
                }
                .overlay(content: {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text.count > 1 && !generating {
                        HStack {
                            Spacer()
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.2)){
                                    selectedOption = text
                                    if !vm.allRestaurants.contains(where: { $0.tag.lowercased() == text.lowercased() }) {
                                        generating = true
                                        
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
                                        vm.loadRestraunts(currentLoc: coords, query: text)
                                    }
                                }
                            }, label: {
                                Image(systemName: "paperplane.fill")
                                    .fontWeight(.light)
                                    .font(.headline).rotationEffect(.degrees(45.0))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14).padding(.vertical, 5)
                                    .background(Color(red: 25 / 255, green: 176 / 255, blue: 255 / 255))
                                    .clipShape(Capsule())
                            })
                        }.padding(.trailing, 8)
                    }
                })
                .clipShape(Capsule())
                .padding(.horizontal, 15).padding(.bottom, 8)
        }
    }
    @ViewBuilder
    func header() -> some View {
        ZStack {
            HStack {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                }, label: {
                    ZStack {
                        Rectangle().foregroundStyle(.gray).opacity(0.001)
                            .frame(width: 50, height: 25)
                        Text("Cancel")
                            .fontWeight(.light)
                            .font(.headline).foregroundStyle(.white)
                    }
                })
                Spacer()
            }
            HStack(spacing: 4){
                Spacer()
                LottieView(loopMode: .loop, name: "finite")
                    .scaleEffect(0.045)
                    .frame(width: 22, height: 10)
                Text("Hustles AI")
                    .bold()
                    .font(.headline).foregroundStyle(.white)
                Spacer()
            }.scaleEffect(1.1)
        }.padding(.horizontal, 15)
    }
}

func getYelpImage(rating: Double) -> String {
    if rating == 0 {
        return "yelp0"
    } else if rating < 1.0 {
        return "yelphalf"
    } else if rating < 1.5 {
        return "yelp1"
    } else if rating < 2.0 {
        return "yelp1half"
    } else if rating < 2.5 {
        return "yelp2"
    } else if rating < 3.0 {
        return "yelp2half"
    } else if rating < 3.5 {
        return "yelp3"
    } else if rating < 4.0 {
        return "yelp3half"
    } else if rating < 4.5 {
        return "yelp4"
    } else if rating < 5.0 {
        return "yelp4half"
    } else {
        return "yelp5"
    }
}

struct DetailsViewPlace: View {
    @State var offset: CGSize = .zero
    let image: String
    @Binding var isExpanded: Bool
    var animationID: Namespace.ID
    @GestureState private var isDragging = false
    @Binding var selected: String?
    
    var body: some View {
        ZStack {
            CardViewPlace(image: image, isExpanded: $isExpanded, animationID: animationID, isDetailsView: true, offset: $offset)
        }
        .gesture (
            DragGesture()
                .updating($isDragging, body: { _, dragState, _ in
                    dragState = true
                }).onChanged({ value in
                    var translation = value.translation
                    translation = isDragging && isExpanded ? translation : .zero
                    offset = translation
                }).onEnded({ value in
                    if value.translation.height > 120 || abs(value.translation.width) > 100 {
                        withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.7, blendDuration: 0.7)) {
                            offset = .zero
                            isExpanded = false
                            selected = nil
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.25)) {
                            offset = .zero
                        }
                    }
                })
        )
    }
}

struct CardViewPlace: View {
    @Environment(\.scenePhase) var scenePhase
    private let screenSize = UIScreen.main.bounds
    let image: String
    @Binding var isExpanded: Bool
    var animationID: Namespace.ID
    var isDetailsView: Bool
    @Binding var offset: CGSize
    
    init(image: String,
         isExpanded: Binding<Bool>,
         animationID: Namespace.ID,
         isDetailsView: Bool,
         offset: Binding<CGSize>) {
        
        self.image = image
        self._isExpanded = isExpanded
        self.isDetailsView = isDetailsView
        self.animationID = animationID
        self._offset = offset
    }
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            KFImage(URL(string: image))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .background(content: {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundColor(.gray).opacity(0.2)
                        .overlay(content: {
                            ProgressView().scaleEffect(1.2)
                        })
                })
                .scaleEffect(scale)
                .contentShape(Rectangle())
        }
        .matchedGeometryEffect(id: image, in: animationID)
        .offset(offset)
        .offset(y: offset.height * -0.4)
    }
    private var scale: CGFloat {
        var yOffset = offset.height
        yOffset = yOffset < 0 ? 0 : yOffset
        var progress = yOffset / screenSize.height
        progress = 1 - (progress > 0.4 ? 0.4 : progress)
        return (isExpanded ? progress : 1)
    }
}

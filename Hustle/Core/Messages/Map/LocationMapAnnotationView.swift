import SwiftUI
import Foundation
import UIKit
import CoreLocation
import Kingfisher

class CompassManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?
    @Published var headingDegrees: CGFloat = 0.0

    override init() {
        super.init()
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        self.locationManager?.startUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.headingDegrees = CGFloat(newHeading.trueHeading)
        }
    }
}

struct LocationMapAnnotationView: View {
    @EnvironmentObject var vm: LocationsViewModel
    @StateObject private var locationManager = CompassManager()
    let item: LocationMap
    let CUID: String
    let isGhost: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0){
                ZStack {
                    Circle()
                        .frame(width: 62, height: 62)
                        .font(.headline)
                        .foregroundStyle(.pink)
                    ZStack {
                        if let first = item.user?.fullname.first {
                            personLetterView(size: 55, letter: String(first))
                        } else {
                            personView(size: 55)
                        }
                        if let image = item.user?.profileImageUrl {
                            KFImage(URL(string: image))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 55, height: 55)
                                .clipShape(Circle())
                        }
                    }
                }
                .overlay {
                    if CUID == (item.user?.id ?? "NOTCURRENT") && isGhost {
                        Image("ghostMode")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 34, height: 34).scaleEffect(1.15)
                            .padding(5)
                            .background(content: {
                                TransparentBlurView(removeAllFilters: true)
                                    .blur(radius: 14, opaque: true)
                                    .background(.white.opacity(0.8))
                            })
                            .clipShape(Circle())
                    }
                }
                .zIndex(1)
                
                Image(systemName: "triangle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.pink)
                    .frame(width: 10, height: 10)
                    .rotationEffect(Angle(degrees: 180))
                    .offset(y: -3)
                    .background(alignment: .top){
                        if CUID == (item.user?.id ?? "NOTCURRENT") {
                            Triangle()
                                .frame(width: 32, height: (locationManager.headingDegrees > 320.0 || locationManager.headingDegrees < 40.0) ? 100 : 75)
                                .rotationEffect(Angle(degrees: 180.0), anchor: .top)
                                .rotationEffect(Angle(degrees: locationManager.headingDegrees), anchor: .top)
                                .foregroundStyle(LinearGradient(colors: [.blue, .blue, .clear], startPoint: .top, endPoint: .bottom))
                                .offset(y: 5)
                        }
                    }
                    .zIndex(0)
            }
            
            if let element = vm.locations.first(where: { $0.id == item.id }), element.shouldShowName {
                HStack(spacing: 2){
                    Text("@\(item.user?.username ?? "----")").foregroundStyle(.black).bold().font(.caption)
                    if element.shouldShowBattery {
                        Image(systemName: getBatteryImage())
                            .foregroundStyle(getBatteryColor())
                            .font(.caption)
                            .transition(.scale.combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.2), value: element.shouldShowBattery)
                    }
                    Text(formatTime())
                        .foregroundStyle(.gray)
                        .font(.caption)
                }
                .padding(3)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .shadow(color: .gray, radius: 3)
                .padding(.bottom, 20)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    func formatTime() -> String {
        guard let lastSeenDate = item.user?.lastSeen?.dateValue() else {
            return "AFK"
        }
        if CUID == (item.user?.id ?? "NOTCURRENT") {
            return "Now"
        }
        
        let currentDate = Date()
        let timeInterval = currentDate.timeIntervalSince(lastSeenDate)
        
        let oneMinute: TimeInterval = 180
        let oneHour: TimeInterval = 3600
        let oneDay: TimeInterval = 86400
        let oneMonth: TimeInterval = 2592000
        
        if timeInterval < oneMinute {
            return "Now"
        } else if timeInterval < oneHour {
            let minutes = Int(timeInterval / oneMinute)
            return "\(minutes)m"
        } else if timeInterval < oneDay {
            let hours = Int(timeInterval / oneHour)
            return "\(hours)h"
        } else if timeInterval < oneMonth {
            let days = Int(timeInterval / oneDay)
            return "\(days)d"
        } else {
            return "AFK"
        }
    }
    func getBatteryImage() -> String {
        var level = item.user?.currentBatteryPercentage
        
        if CUID == (item.user?.id ?? "NOTCURRENT") {
            level = currBattery()
        }
        
        if let level {
            if level < 0.05 {
                return "battery.0percent"
            } else if level < 0.3 {
                return "battery.25percent"
            } else if level < 0.6 {
                return "battery.50percent"
            } else if level < 0.8 {
                return "battery.75percent"
            } else {
                return "battery.100percent"
            }
        } else {
            return "battery.75percent"
        }
    }
    func getBatteryColor() -> Color {
        var level = item.user?.currentBatteryPercentage
        
        if CUID == (item.user?.id ?? "NOTCURRENT") {
            level = currBattery()
        }
        
        if let level {
            if level < 0.2 {
                return .red
            } else if level < 0.55 {
                return .yellow
            } else {
                return .green
            }
        } else {
            return .green
        }
    }
}

struct LocationGroupAnnotationView: View {
    @EnvironmentObject var vm: LocationsViewModel
    @Binding var item: groupLocation
    
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                ZStack {
                    Circle()
                        .frame(width: 50).foregroundStyle(.gray).opacity(0.4)
                        .offset(y: 56).scaleEffect(y: 0.55)
                    Circle()
                        .frame(width: 50).foregroundStyle(.white)
                        .offset(y: 50).scaleEffect(y: 0.55)
                }
                if item.allLocs.count == 2 {
                    let image1 = item.allLocs[0].user?.profileImageUrl ?? String(item.allLocs[0].user?.fullname.first ?? Character(""))

                    singleAnn(color: .orange, image: image1)
                        .offset(x: 12, y: -2).rotationEffect(.degrees(15))
                    
                    let image2 = item.allLocs[1].user?.profileImageUrl ?? String(item.allLocs[1].user?.fullname.first ?? Character(""))
                    
                    singleAnn(color: .blue, image: image2).offset(x: -12, y: -2).rotationEffect(.degrees(-15))
                } else {
                    if item.allLocs.count > 6 {
                        let image7 = item.allLocs[6].user?.profileImageUrl ?? String(item.allLocs[6].user?.fullname.first ?? Character(""))
                        
                        singleAnn(color: .indigo, image: image7)
                            .scaleEffect(0.5)
                            .offset(x: -22, y: -44).rotationEffect(.degrees(-15))
                    }
                    
                    if item.allLocs.count > 5 {
                        let image6 = item.allLocs[5].user?.profileImageUrl ?? String(item.allLocs[5].user?.fullname.first ?? Character(""))
                        
                        singleAnn(color: .black, image: image6)
                            .scaleEffect(0.5)
                            .offset(x: 22, y: -44).rotationEffect(.degrees(15))
                    }
                    
                    if item.allLocs.count > 4 {
                        let image5 = item.allLocs[4].user?.profileImageUrl ?? String(item.allLocs[4].user?.fullname.first ?? Character(""))
                        
                        singleAnn(color: .purple, image: image5)
                            .scaleEffect(0.6)
                            .offset(x: -1, y: -48).rotationEffect(.degrees(15))
                    }
                    
                    if item.allLocs.count > 3 {
                        let image4 = item.allLocs[3].user?.profileImageUrl ?? String(item.allLocs[3].user?.fullname.first ?? Character(""))
                        
                        singleAnn(color: .green, image: image4)
                            .scaleEffect(0.6)
                            .offset(x: 1, y: -48).rotationEffect(.degrees(-15))
                    }
                    
                    if item.allLocs.count >= 3 {
                        let image3 = item.allLocs[2].user?.profileImageUrl ?? String(item.allLocs[2].user?.fullname.first ?? Character(""))
                        
                        singleAnn(color: .pink, image: image3)
                            .offset(x: -16, y: -6).rotationEffect(.degrees(-20))
                        
                        let image2 = item.allLocs[1].user?.profileImageUrl ?? String(item.allLocs[1].user?.fullname.first ?? Character(""))
                        
                        singleAnn(color: .orange, image: image2)
                            .offset(x: 16, y: -6).rotationEffect(.degrees(20))
                    }
                    
                    if let first = item.allLocs.first {
                        let image1 = first.user?.profileImageUrl ?? String(first.user?.fullname.first ?? Character(""))
                        
                        singleAnn(color: .blue, image: image1)
                    }
                }
            }
        
            if item.shouldShowName {
                HStack(spacing: 2){
                    Text("@\(item.allLocs.first(where: { !($0.user?.username ?? "").isEmpty })?.user?.username ?? "") & \(item.allLocs.count - 1) more").foregroundStyle(.black).bold().font(.caption)
                }
                .padding(3)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .shadow(color: .gray, radius: 3)
                .padding(.bottom, 20)
                .transition(.scale.combined(with: .opacity))
                .animation(.easeInOut(duration: 0.15), value: item.shouldShowName)
            }
        }
    }
    func singleAnn(color: Color, image: String) -> some View {
        VStack(spacing: 0){
            ZStack {
                Circle()
                    .frame(width: 52, height: 52)
                    .font(.headline)
                    .foregroundStyle(color)
                
                if image.count == 1 {
                    Text(image.uppercased()).font(.title2).fontWeight(.heavy).foregroundStyle(.white)
                }
                
                KFImage(URL(string: image))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())
            }
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(color)
                .frame(width: 10, height: 10)
                .rotationEffect(Angle(degrees: 180))
                .offset(y: -3)
        }
    }
}

struct CustomPin: View {    
    @State var show: Bool = false
    @State var scale = 0.0
    @State var scaleInit = 0.0
    let image: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Image(systemName: "drop.fill")
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(y: 0.75)
                    .foregroundStyle(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(180.0))
                
                ZStack {
                    Circle()
                        .frame(width: 32, height: 32)
                        .foregroundStyle(.blue)
                        .overlay {
                            if let first = image.first {
                                Text(String(first)).font(.title3).fontWeight(.heavy).foregroundStyle(.white)
                            } else {
                                Image(systemName: "mappin")
                                    .font(.headline).foregroundStyle(.white)
                            }
                        }
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                }.offset(y: -5)
            }
            .opacity(show ? 1.0 : 0.0)
            .scaleEffect(scale)
            Circle().frame(width: 8)
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

struct StoryMapAnnotation: View {
    @State var preview: UIImage? = nil
    @State var scale = 0.0
    @EnvironmentObject var vm: LocationsViewModel
    let item: groupLocation?
    let single: LocationMap?
    @Binding var currentID: String
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .frame(width: 16, height: 16)
                .rotationEffect(Angle(degrees: 180))
                .offset(y: 10)
                .scaleEffect((currentID == (item?.id ?? "NA") || currentID == (single?.id ?? "NA")) ? 0.8 : 1.0)
            if let data = single ?? item?.allLocs.first(where: { $0.memory?.image != nil }) ?? item?.allLocs.first(where: { $0.story?.imageURL != nil }) ?? item?.allLocs.first {
                if let image = data.memory?.image ?? data.story?.imageURL {
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 46, height: 91)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding((currentID == (item?.id ?? "NA") || currentID == (single?.id ?? "NA")) ? 2 : 3)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let image = preview ?? data.preview {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 46, height: 91)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding((currentID == (item?.id ?? "NA") || currentID == (single?.id ?? "NA")) ? 2 : 3)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let vid = data.memory?.video ?? data.story?.videoURL {
                    ZStack {
                        Color(UIColor.lightGray)
                            .frame(width: 46, height: 91)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding((currentID == (item?.id ?? "NA") || currentID == (single?.id ?? "NA")) ? 2 : 3)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        ProgressView()
                    }
                    .onAppear {
                        if let url = URL(string: vid) {
                            extractImageAt(f_url: url, time: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)) { thumbnail in
                                self.preview = thumbnail
                                if let idx = vm.stories.firstIndex(where: { $0.id == data.id }) {
                                    vm.stories[idx].preview = thumbnail
                                } else if let idx = vm.memories.firstIndex(where: { $0.id == data.id }) {
                                    vm.memories[idx].preview = thumbnail
                                }
                            }
                        }
                    }
                }
            }
        }
        .shadow(color: .gray, radius: (currentID == (item?.id ?? "NA") || currentID == (single?.id ?? "NA")) ? 1.0 : 3.0)
        .overlay(alignment: .topTrailing){
            if (item?.allLocs.count ?? 0) > 1 {
                Text("\(item?.allLocs.count ?? 2)").font(.system(size: 15)).bold()
                    .foregroundStyle(.black)
                    .padding(6)
                    .background(.white)
                    .clipShape(Circle())
                    .scaleEffect((currentID == (item?.id ?? "NA") || currentID == (single?.id ?? "NA")) ? 0.7 : 1.0)
                    .offset(x: 10, y: -10)
            }
        }
        .scaleEffect(scale)
        .scaleEffect((currentID == (item?.id ?? "NA") || currentID == (single?.id ?? "NA")) ? 2.0 : 1.0, anchor: .bottom)
        .animation(.smooth(duration: 0.2, extraBounce: 0.6), value: currentID)
        .onAppear {
            withAnimation(.smooth(duration: 0.3, extraBounce: 0.6)){
                scale = 1.0
            }
        }
        .onDisappear(perform: {
            scale = 0.0
        })
    }
}

struct BusinessMapAnnotation: View {
    @State var scale = 0.0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var lastSwitch = 0
    @State var indexToShow: Int = 0
    
    let photos: [String]
    let id: String
    @Binding var currentID: String
    let businessCount: Int
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .frame(width: 16, height: 16)
                .rotationEffect(Angle(degrees: 180))
                .offset(y: 10)
                .scaleEffect((currentID == id ? 0.8 : 1.0))
            
            if indexToShow < photos.count {
                KFImage(URL(string: photos[indexToShow]))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(currentID == id ? 2 : 3)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .transition(.move(edge: .trailing))
                    .animation(.easeInOut, value: indexToShow)
            } else {
                Image(systemName: "fork.knife")
                    .font(.subheadline)
                    .frame(width: 60, height: 60)
                    .background(.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(currentID == id ? 2 : 3)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .overlay(alignment: .topTrailing){
            if businessCount > 1 {
                Text("\(businessCount)").font(.system(size: 15)).bold()
                    .foregroundStyle(.black)
                    .padding(6)
                    .background(.white)
                    .clipShape(Circle())
                    .scaleEffect(currentID == id ? 0.5 : 0.8)
                    .offset(x: 7, y: -12)
            }
        }
        .onReceive(timer, perform: { _ in
            if photos.count > 0 && currentID == id {
                if lastSwitch == 1 {
                    lastSwitch = 0
                    if (indexToShow + 1) < photos.count {
                        indexToShow += 1
                    } else {
                        indexToShow = 0
                    }
                } else {
                    lastSwitch += 1
                }
            }
        })
        .shadow(color: .gray, radius: 1.0)
        .scaleEffect(scale)
        .scaleEffect((currentID == id ? 1.9 : 1.0), anchor: .bottom)
        .animation(.smooth(duration: 0.2, extraBounce: 0.6), value: currentID)
        .onAppear {
            withAnimation(.smooth(duration: 0.3, extraBounce: 0.6)){
                scale = 1.0
            }
        }
        .onDisappear(perform: {
            scale = 0.0
        })
        .padding(.bottom, 10)
    }
}

struct SimpleSendYelp: View {
    @State private var showForward = false
    @State var sendLink: String = ""
    let placeID: String
    
    var body: some View {
        VStack(spacing: 10){
            Button(action: {
                sendLink = "https://hustle.page/yelp/\(placeID)/"
                showForward = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }, label: {
                HStack(spacing: 5){
                    Spacer()
                    Text("Share")
                        .foregroundStyle(.white)
                        .font(.headline)
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .font(.headline).rotationEffect(.degrees(45.0))
                    Spacer()
                }
                .frame(height: 36)
                .background(Color(red: 5 / 255, green: 176 / 255, blue: 255 / 255))
                .clipShape(Capsule())
            })
        }
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendLink)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
        })
    }
}

struct SinglePlaceSheetView: View {
    @Namespace private var animation
    @State private var isExpanded: Bool = false
    @State private var expandedID: String?
    @State var showMenu = false
    @State var showFullHours = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Binding var show: Bool
    let daysMap = [
        0: "Sunday",
        1: "Monday",
        2: "Tuesday",
        3: "Wednesday",
        4: "Thursday",
        5: "Friday",
        6: "Saturday"
    ]
    
    let place: mainBusiness
    let dropPin: () -> Void
    
    var body: some View {
        VStack(spacing: 10){
            HStack(alignment: .top, spacing: 8) {
                ZStack {
                    let image = getImageForPlace(categories: place.business.categories)
                    Image(systemName: image)
                        .font(.title2)
                        .frame(width: 65, height: 65)
                        .background(.gray.opacity(0.3))
                        .clipShape(Circle())
                    if let image = place.business.image_url ?? place.business.photos?.first {
                        KFImage(URL(string: image))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 65, height: 65)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                }
                VStack(alignment: .leading, spacing: 5){
                    Text(place.business.name ?? "")
                        .font(.title3).bold()
                    HStack(spacing: 4){
                        Text(getFirstThreeUniqueAliasesOrTitles(categories: place.business.categories))
                        Text("-")
                        let t1 = String(repeating: "$", count: place.business.price?.count ?? 2)
                        let t2 = String(repeating: "$", count: 4 - t1.count)
                        HStack(spacing: 0.5){
                            Text(t1).foregroundStyle(colorScheme == .dark ? .white : .black)
                            Text(t2)
                        }
                        Spacer()
                    }.font(.caption).foregroundStyle(.gray)
                    HStack(spacing: 4){
                        if let hours = place.business.hours?.first {
                            let status = isCurrentlyOpen(hours: hours)
                            Text(status ? "Open Now" : "Closed Now")
                                .font(.caption).bold()
                                .foregroundStyle(status ? .green : .red)
                            Text("-")
                        } else if let status = place.business.hours?.first?.is_open_now {
                            Text(status ? "Open Now" : "Closed Now")
                                .font(.caption).bold()
                                .foregroundStyle(status ? .green : .red)
                            Text("-")
                        }
                        Text(String(format: "%.1f mi", place.distanceFromMe))
                        if let city = place.business.location?.city {
                            Text("-")
                            Text(city)
                        }
                    }
                    .foregroundStyle(.gray)
                    .font(.caption)
                }
                Spacer()
                Button(action: {
                    show = false
                    dismiss()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label: {
                    ZStack {
                        Circle()
                            .frame(width: 38, height: 38)
                            .foregroundStyle(.gray.opacity(colorScheme == .dark ? 0.3 : 0.13))
                        Image(systemName: "xmark")
                            .font(.subheadline).bold()
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                })
            }
            ScrollView {
                HStack {
                    HStack(spacing: 4){
                        Image(systemName: "hand.thumbsup.fill")
                            .foregroundStyle(.yellow).rotationEffect(.degrees(-20.0))
                        Text(String(format: "%.1f", place.business.rating ?? 0.0))
                            .font(.subheadline)
                    }
                    .padding(6)
                    .background(.gray.opacity(colorScheme == .dark ? 0.3 : 0.1))
                    .clipShape(Capsule())
                    Spacer()
                    Text("\(place.business.review_count ?? 0) Ratings")
                        .font(.caption)
                    Image(getYelpImage(rating: place.business.rating ?? 0.0))
                }.padding(.leading, 4)
                HStack(spacing: 12){
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dropPin()
                    }, label: {
                        HStack(spacing: 5){
                            Image(systemName: "mappin.and.ellipse")
                                .font(.headline).foregroundStyle(.red)
                            Text("Pin")
                                .font(.headline)
                        }
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .frame(width: 110, height: 36)
                        .background(.gray.opacity(colorScheme == .dark ? 0.4 : 0.2))
                        .clipShape(Capsule())
                    })
                    Button(action: {
                        openMaps(lat: place.coordinates.latitude, long: place.coordinates.longitude, name: place.business.name ?? "")
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }, label: {
                        HStack(spacing: 5){
                            Image(systemName: "car.fill")
                                .font(.headline)
                            if let timeStr = place.timeDistance {
                                Text(timeStr.isEmpty ? "-- min" : timeStr).font(.headline)
                            } else {
                                ProgressView()
                            }
                        }
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .frame(width: 110, height: 36)
                        .background(.gray.opacity(colorScheme == .dark ? 0.4 : 0.2))
                        .clipShape(Capsule())
                    })
                    SimpleSendYelp(placeID: place.business.id ?? "")
                }
                let photos = place.business.photos
                let hours = place.business.hours
                if photos == nil && hours == nil {
                    LottieView(loopMode: .loop, name: "placeLoader")
                        .frame(width: 85, height: 85)
                        .scaleEffect(0.5)
                }
                if let photos = photos {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(photos, id: \.self) { image in
                                CardViewPlace(image: image, isExpanded: $isExpanded, animationID: animation, isDetailsView: false, offset: .constant(.zero))
                                    .frame(width: 135, height: 220)
                                    .onTapGesture {
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.8)) {
                                            expandedID = image
                                            isExpanded = true
                                        }
                                    }
                            }
                        }
                    }.scrollIndicators(.hidden).padding(.top, 8)
                }
                if let hours = hours?.first {
                    HStack(alignment: .top, spacing: 12){
                        Image(systemName: "clock")
                            .font(.system(size: 18))
                        VStack {
                            HStack(spacing: 12){
                                VStack(alignment: .leading, spacing: 4){
                                    let isOpen = isCurrentlyOpen(hours: hours)
                                    Text(isOpen ? "Open Now" : "Closed Now")
                                        .foregroundStyle(isOpen ? .green : .red)
                                        .bold().font(.headline)
                                    if let range = getOpenRangeForToday(hours: hours), !showFullHours {
                                        Text(range)
                                            .foregroundStyle(.gray)
                                            .font(.subheadline)
                                    }
                                }
                                Spacer()
                                Image(systemName: showFullHours ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 16)).bold()
                                    .contentTransition(.symbolEffect(.replace))
                            }
                       
                            if let open = hours.open, showFullHours {
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
                                        }
                                        .font(.system(size: 16))
                                    }
                                }.padding(.top, 5)
                            }
                        }
                    }
                    .padding(.horizontal).padding(.vertical, 10)
                    .background(.gray.opacity(colorScheme == .dark ? 0.3 : 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        if hours.open != nil {
                            withAnimation(.easeInOut(duration: 0.2)){
                                showFullHours.toggle()
                            }
                        }
                    }
                    .padding(.top)
                }
                VStack(spacing: 10){
                    if let addy = place.business.location {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)){
                                showMenu = true
                            }
                        }, label: {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                VStack(alignment: .leading, spacing: 2){
                                    Text("Address").fontWeight(.regular)
                                    Text(constructAddress(from: addy))
                                        .font(.system(size: 13)).foregroundStyle(.gray)
                                        .multilineTextAlignment(.leading)
                                }.padding(.trailing, 13)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline)
                        })
                    }
                    if let phone = place.business.phone {
                        if place.business.location != nil {
                            Divider()
                        }
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            callNumber(phoneNumber: phone)
                        }, label: {
                            HStack {
                                Image(systemName: "phone.fill")
                                VStack(alignment: .leading, spacing: 2){
                                    Text("Call").fontWeight(.regular)
                                    Text(phone)
                                        .font(.system(size: 13)).foregroundStyle(.gray)
                                        .multilineTextAlignment(.leading)
                                }.padding(.trailing, 13)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline)
                        })
                    }
                    if let site = place.business.url {
                        if place.business.location != nil || place.business.phone != nil {
                            Divider()
                        }
                        Button(action: {
                            if let url = URL(string: site) {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }, label: {
                            HStack {
                                Image(systemName: "globe.americas.fill")
                                VStack(alignment: .leading, spacing: 2){
                                    Text("Visit Site").fontWeight(.regular)
                                    Text(site)
                                        .lineLimit(1)
                                        .font(.system(size: 13)).foregroundStyle(.gray)
                                        .multilineTextAlignment(.leading)
                                }.padding(.trailing, 13)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(colorScheme == .dark ? .white : .black).font(.headline)
                        })
                    }
                }
                .padding(.horizontal).padding(.vertical, 10)
                .background(.gray.opacity(colorScheme == .dark ? 0.3 : 0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top)
                HStack {
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
                }.padding(.top, 10)
            }.scrollIndicators(.hidden)
        }
        .padding(.horizontal, 10).padding(.top)
        .overlay {
            if showMenu || isExpanded {
                TransparentBlurView(removeAllFilters: true)
                    .blur(radius: 10, opaque: true)
                    .background(.gray.opacity(0.4))
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)){
                            showMenu = false
                            isExpanded = false
                            expandedID = nil
                        }
                    }
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
                        .padding(.bottom, 15)
                }.padding(.top, 15)
            }
        }
        .overlay(alignment: .bottom){
            if showMenu {
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
                                showMenu = false
                            }
                            openMaps(lat: place.coordinates.latitude, long: place.coordinates.longitude, name: place.business.name ?? "")
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
                                    showMenu = false
                                }
                                if let url = URL(string: "comgooglemaps-x-callback://?saddr=&daddr=\(place.coordinates.latitude),\(place.coordinates.longitude)&directionsmode=driving") {
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
                                showMenu = false
                            }
                            if let addy = place.business.location {
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
                                    if let addy = place.business.location {
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
                            showMenu = false
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

struct MultiSheetView: View {
    @EnvironmentObject var vm: LocationsViewModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var show: Bool
    let near: String
    let close: (String) -> Void
    
    var body: some View {
        VStack(spacing: 6){
            HStack(spacing: 8){
                Image(systemName: "person.3.fill")
                    .font(.title3)
                    .frame(width: 55, height: 55)
                    .background(.gray.opacity(colorScheme == .dark ? 0.3 : 0.13))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4){
                    Text("\(vm.multiBusiness.count) Places").font(.headline).bold()
                    Text(near).font(.subheadline).foregroundStyle(.gray)
                }
                Spacer()
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    show = false
                }, label: {
                    ZStack {
                        Circle()
                            .frame(width: 38, height: 38)
                            .foregroundStyle(.gray.opacity(colorScheme == .dark ? 0.3 : 0.13))
                        Image(systemName: "xmark")
                            .font(.subheadline).bold()
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                })
            }
            .padding(.horizontal, 12)
            ScrollView {
                LazyVStack(spacing: 10){
                    if vm.multiBusiness.isEmpty {
                        LottieView(loopMode: .loop, name: "placeLoader")
                            .frame(width: 85, height: 85)
                            .scaleEffect(0.7)
                            .padding(.top, 100)
                    } else {
                        Color.clear.frame(height: 10)
                        ForEach(vm.multiBusiness, id: \.self) { placeID in
                            if let first = vm.allRestaurants.first(where: { $0.business.id == placeID }) {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    close(placeID)
                                }, label: {
                                    SinglePlaceRowView(place: first)
                                })
                            }
                        }
                    }
                }
            }.scrollIndicators(.hidden)
        }.padding(.top)
    }
}

struct TagSheetView: View {
    @EnvironmentObject var vm: LocationsViewModel
    @Environment(\.colorScheme) var colorScheme
    let photos = ["Restaurants": "fork.knife", "Cafes": "cup.and.saucer.fill", "Parks": "photo", "Ice Cream": "birthday.cake.fill"]
    @Binding var show: Bool
    let close: (String?) -> Void
    
    var body: some View {
        VStack(spacing: 6){
            let allMatches = allMatches()
            HStack(spacing: 8){
                let isMember = vm.tags.contains(vm.selectedTag)
                if isMember {
                    Image(systemName: photos[vm.selectedTag] ?? "fork.knife")
                        .font(.title3)
                        .frame(width: 55, height: 55)
                        .background(.gray.opacity(colorScheme == .dark ? 0.3 : 0.13))
                        .clipShape(Circle())
                } else {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .frame(width: 55, height: 55)
                        .background(.gray.opacity(colorScheme == .dark ? 0.3 : 0.13))
                        .clipShape(Circle())
                }
                VStack(alignment: .leading, spacing: 4){
                    Text(isMember ? vm.selectedTag : "'\(vm.selectedTag)'").font(.headline).bold()
                    HStack(spacing: 7){
                        if vm.searchingPlaces {
                            Text("Searching...").font(.subheadline).foregroundStyle(.gray)
                        } else if allMatches.isEmpty {
                            Text("No Results").font(.subheadline).foregroundStyle(.gray)
                        } else {
                            Text("\(allMatches.count) Places").font(.subheadline).foregroundStyle(.gray)
                        }
                        Text("-").font(.subheadline).foregroundStyle(.gray)
                        Button {
                            close(nil)
                        } label: {
                            Text("Edit Search").font(.subheadline).foregroundStyle(.blue)
                        }
                    }
                }
                Spacer()
                Button(action: {
                    show = false
                }, label: {
                    ZStack {
                        Circle()
                            .frame(width: 38, height: 38)
                            .foregroundStyle(.gray.opacity(colorScheme == .dark ? 0.3 : 0.13))
                        Image(systemName: "xmark")
                            .font(.subheadline).bold()
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                })
            }
            .padding(.horizontal, 12)
            ScrollView {
                LazyVStack(spacing: 10){
                    if allMatches.isEmpty {
                        if vm.searchingPlaces {
                            LottieView(loopMode: .loop, name: "placeLoader")
                                .frame(width: 85, height: 85)
                                .scaleEffect(0.7)
                                .padding(.top, 100)
                        } else {
                            Text("No Search Results for \(vm.selectedTag)").font(.subheadline).foregroundStyle(.gray)
                                .padding(.top, 100)
                        }
                    } else {
                        Color.clear.frame(height: 10)
                        ForEach(allMatches) { place in
                            Button {
                                close(place.business.id)
                            } label: {
                                SinglePlaceRowView(place: place)
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }.padding(.top)
    }
    func allMatches() -> [mainBusiness] {
        var final: [mainBusiness] = []
        vm.allRestaurants.forEach { element in
            if element.tag == vm.selectedTag {
                final.append(element)
            }
        }
         return final
    }
}

struct SinglePlaceRowView: View {
    @Environment(\.colorScheme) var colorScheme
    let place: mainBusiness
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                let image = getImageForPlace(categories: place.business.categories)
                Image(systemName: image)
                    .font(.title2)
                    .frame(width: 65, height: 65)
                    .background(.gray.opacity(0.3))
                    .clipShape(Circle())
                if let image = place.business.image_url ?? place.business.photos?.first {
                    KFImage(URL(string: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 65, height: 65)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
            VStack(alignment: .leading, spacing: 5){
                Text(place.business.name ?? "")
                    .font(.headline).bold().multilineTextAlignment(.leading).lineLimit(2)
                HStack(spacing: 4){
                    Text(getFirstThreeUniqueAliasesOrTitles(categories: place.business.categories))
                        .multilineTextAlignment(.leading).lineLimit(2)
                    Text("-")
                    let t1 = String(repeating: "$", count: place.business.price?.count ?? 2)
                    let t2 = String(repeating: "$", count: 4 - t1.count)
                    HStack(spacing: 0.5){
                        Text(t1).foregroundStyle(colorScheme == .dark ? .white : .black)
                        Text(t2)
                    }
                    Spacer()
                }.font(.caption).foregroundStyle(.gray)
                HStack(spacing: 4){
                    if let status = place.business.hours?.first?.is_open_now {
                        Text(status ? "Open Now" : "Closed Now")
                            .font(.caption)
                            .foregroundStyle(status ? .green : .red)
                        Text("-")
                    }
                    Text(String(format: "%.1f mi", place.distanceFromMe))
                }
                .foregroundStyle(.gray)
                .font(.caption)
            }.foregroundStyle(colorScheme == .dark ? .white : .black)
            Spacer()
            HStack(spacing: 4){
                Image(systemName: "hand.thumbsup.fill")
                    .foregroundStyle(.yellow).rotationEffect(.degrees(-20.0))
                Text(String(format: "%.1f", place.business.rating ?? 0.0))
                    .font(.subheadline)
            }
            .padding(6)
            .background(.gray.opacity(colorScheme == .dark ? 0.3 : 0.1))
            .clipShape(Capsule())
            .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
        .padding(10)
        .background(colorScheme == .dark ? .black : .white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
        .shadow(color: .gray.opacity(0.6), radius: 8)
    }
}

func getImageForPlace(categories: [Category]?) -> String {
    let tags = ["Restaurants", "Cafes", "Parks", "Ice Cream"]
    let photos = ["Restaurants": "fork.knife", "Cafes": "cup.and.saucer.fill", "Parks": "photo", "Ice Cream": "birthday.cake.fill"]

    if let items = categories {
        for element in items {
            for look in tags {
                if (element.alias ?? "").contains(look) || (element.title ?? "").contains(look) {
                    return photos[look] ?? "fork.knife"
                }
            }
        }
    }
    return "fork.knife"
}

func getFirstThreeUniqueAliasesOrTitles(categories: [Category]?) -> String {
    var uniqueAliases: [String] = []
    var uniqueTitles: [String] = []

    if let items = categories {
        for element in items {
            if let alias = element.alias, !uniqueAliases.contains(where: { $0.caseInsensitiveCompare(alias) == .orderedSame }) {
                if !uniqueAliases.contains(where: { $0.lowercased() == alias.lowercased() }) && !uniqueTitles.contains(where: { $0.lowercased() == alias.lowercased() }){
                    uniqueAliases.append(alias)
                }
            }
            if uniqueAliases.count >= 3 {
                break
            }
        }
        
        if uniqueAliases.count < 3 {
            for element in items {
                if let title = element.title, !uniqueTitles.contains(where: { $0.caseInsensitiveCompare(title) == .orderedSame }) {
                    if !uniqueTitles.contains(where: { $0.lowercased() == title.lowercased() }) && !uniqueAliases.contains(where: { $0.lowercased() == title.lowercased() }) {
                        uniqueTitles.append(title)
                    }
                }
                if uniqueTitles.count >= 3 {
                    break
                }
            }
        }
    }
    
    let resultAliases = uniqueAliases.prefix(3)
    let resultTitles = uniqueTitles.prefix(3)
    
    if resultAliases.count == 3 {
        return resultAliases.joined(separator: ", ")
    } else if resultTitles.count == 3 {
        return resultTitles.joined(separator: ", ")
    } else {
        return (resultAliases + resultTitles).prefix(3).joined(separator: ", ")
    }
}

func constructAddress(from location: LocationYelp) -> String {
    var addressComponents: [String] = []
    
    if let address1 = location.address1, !address1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        addressComponents.append(address1)
    }
    if let address2 = location.address2, !address2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        addressComponents.append(address2)
    }
    if let address3 = location.address3, !address3.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        addressComponents.append(address3)
    }
    if let city = location.city, !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        addressComponents.append(city)
    }
    if let state = location.state, !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        addressComponents.append(state)
    }
    if let zip_code = location.zip_code, !zip_code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        addressComponents.append(zip_code)
    }
    if let country = location.country, !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        addressComponents.append(country)
    }
 
    return addressComponents.joined(separator: ", ")
}

func callNumber(phoneNumber: String) {
    guard let url = URL(string: "telprompt://\(phoneNumber)"),
        UIApplication.shared.canOpenURL(url) else {
        return
    }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
}

func isCurrentlyOpen(hours: Hours) -> Bool {
    guard let openHours = hours.open else { return false }
    
    let currentDate = Date()
    let calendar = Calendar.current
    let currentDay = calendar.component(.weekday, from: currentDate) - 1
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HHmm"
    let currentTimeString = dateFormatter.string(from: currentDate)
    
    guard let currentTime = Int(currentTimeString) else { return false }
    
    for open in openHours {
        guard let day = open.day, let start = open.start, let end = open.end else { continue }
        guard let startTime = Int(start), let endTime = Int(end) else { continue }
        
        if day == currentDay {
            if let isOvernight = open.is_overnight, isOvernight {
                if currentTime >= startTime || currentTime <= endTime {
                    return true
                }
            } else {
                if currentTime >= startTime && currentTime <= endTime {
                    return true
                }
            }
        }
    }
    
    return false
}

func formatTime(_ time: String?) -> (String, String) {
    guard let time = time, time.count == 4 else {
        return ("", "")
    }
    
    let hourString = String(time.prefix(2))
    let minuteString = String(time.suffix(2))
    
    guard let hour = Int(hourString), let minute = Int(minuteString) else {
        return ("", "")
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HHmm"
    
    let dateComponents = DateComponents(hour: hour, minute: minute)
    let calendar = Calendar.current
    guard let date = calendar.date(from: dateComponents) else {
        return ("", "")
    }
    
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "h:mm a"
    
    let formattedTime = timeFormatter.string(from: date)
    let timeParts = formattedTime.split(separator: " ")
    
    guard timeParts.count == 2 else {
        return ("", "")
    }
    
    return (String(timeParts[0]), String(timeParts[1]))
}

func formatOpenTimes(open: Open) -> (String, String, String, String) {
    let (startTime, startPeriod) = formatTime(open.start)
    let (endTime, endPeriod) = formatTime(open.end)
    
    return (startTime, startPeriod, endTime, endPeriod)
}

func getOpenRangeForToday(hours: Hours) -> String? {
    guard let openHours = hours.open else { return nil }
    
    let currentDate = Date()
    let calendar = Calendar.current
    let currentDay = calendar.component(.weekday, from: currentDate) - 1

    for open in openHours {
        if open.day == currentDay {
            let (startTime, startPeriod) = formatTime(open.start)
            let (endTime, endPeriod) = formatTime(open.end)
            return "\(startTime) \(startPeriod) - \(endTime) \(endPeriod)"
        }
    }
    
    return nil
}

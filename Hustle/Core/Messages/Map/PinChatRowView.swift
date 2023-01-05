import SwiftUI
import CoreLocation
import MapKit
import Firebase

struct PinChatRowView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var mapCameraPosition = MapCameraPosition.automatic
    @State var coords: CLLocationCoordinate2D? = nil
    @State var name: String = ""
    @State var timeStr: String = "5:18PM - 6/18/24"
    @State var distance = 0.0
    @State private var showForward = false
    @State var sendLink: String = ""
    let pinStr: String
    let personName: String
    let personImage: String
    let timestamp: Timestamp
    let currentLoc: CLLocationCoordinate2D?
    let isChat: Bool
    let openMap: () -> Void
    
    var body: some View {
        VStack(spacing: 4){
            HStack {
                Text("\(personName) Pinned")
                    .font(.subheadline).bold()
                Spacer()
                Text(timeStr)
                    .font(.caption)
            }
            Map(position: $mapCameraPosition) {
                if let location = coords {
                    Annotation(name, coordinate: location) {
                        CustomPin(image: personImage)
                    }
                }
            }
            .disabled(true)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            HStack {
                Text("\(String(format: "%.1f", distance))m").font(.caption).fontWeight(.light)
                Spacer()
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    sendLink = pinStr
                    showForward = true
                }, label: {
                    ZStack {
                        Rectangle().foregroundStyle(.gray).opacity(0.001)
                            .frame(width: 35, height: 20)
                        Image(systemName: "paperplane")
                            .rotationEffect(.degrees(45.0))
                            .font(.headline)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                })
                Button(action: {
                    if let coord = coords {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        openMaps(lat: coord.latitude, long: coord.longitude, name: name)
                    }
                }, label: {
                    ZStack {
                        Rectangle().foregroundStyle(.gray).opacity(0.001)
                            .frame(width: 50, height: 20)
                        Image(systemName: "car")
                            .font(.headline)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                })
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    openMap()
                }, label: {
                    Text("Open in Map")
                        .font(.caption).foregroundStyle(.blue)
                        .fontWeight(.heavy)
                })
            }
        }
        .frame(maxWidth: widthOrHeight(width: true) * 0.7)
        .frame(height: 175)
        .padding(8)
        .background(content: {
            if isChat {
                Color.gray.opacity(0.25)
            }
        })
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(content: {
            if isChat {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.red, lineWidth: 0.5)
            }
        })
        .onAppear(perform: {
            if let result = extractLatLongName(from: pinStr) {
                self.name = result.name
                self.coords = CLLocationCoordinate2D(latitude: result.latitude, longitude: result.longitude)
                
                if let myLoc = self.currentLoc {
                    let pos1 = CLLocation(latitude: myLoc.latitude, longitude: myLoc.longitude)
                    let pos2 = CLLocation(latitude: result.latitude, longitude: result.longitude)
                    
                    let distanceInMeters = pos1.distance(from: pos2)
                    self.distance = distanceInMeters / 1609.34
                }
                
                self.mapCameraPosition = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: result.latitude, longitude: result.longitude), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)))
            }
            setTime()
        })
        .sheet(isPresented: $showForward, content: {
            SendProfileView(sendLink: $sendLink)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
        })
    }
    func setTime() {
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "h:mma"
        } else {
            formatter.dateFormat = "h:mma - M/d/yy"
        }
        
        self.timeStr = formatter.string(from: date)
    }
}

func extractLatLongName(from string: String) -> (latitude: CGFloat, longitude: CGFloat, name: String)? {
    let components = string.split(separator: ",")

    guard components.count == 3,
          let lat = Double(components[0].trimmingCharacters(in: .whitespaces)),
          let long = Double(components[1].trimmingCharacters(in: .whitespaces)) else {
        return nil
    }
    let name = String(components[2].trimmingCharacters(in: .whitespaces))

    return (latitude: CGFloat(lat), longitude: CGFloat(long), name: name)
}

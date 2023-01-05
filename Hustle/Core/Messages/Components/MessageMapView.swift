import SwiftUI
import MapKit

struct MessageMapView: View {
    let leading: Bool
    let long: Double
    let lat: Double
    let name: String
    @State private var showForward: Bool = false
    @State private var forwardString = ""
    @State private var forwardDataType: Int = 4
    @EnvironmentObject var popRoot: PopToRoot
    
    var body: some View {
        HStack(spacing: 10){
            if leading {
                optionButtons()
            }
            let startPosition = MapCameraPosition.region (
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: long),
                    span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
                )
            )
            
            Map(initialPosition: startPosition) {
                Marker(name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long))
            }
            .frame(height: 270)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            
            if !leading {
                optionButtons()
            }
        }
        .sheet(isPresented: $showForward, content: {
            ForwardContentView(sendLink: $forwardString, whichData: $forwardDataType)
                .presentationDragIndicator(.visible)
                .presentationDetents([.fraction(0.65), .large])
                .onDisappear {
                    showForward = false
                }
        })
    }
    func optionButtons() -> some View {
        VStack(spacing: 10){
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                forwardString = "https://hustle.page/location/lat=\(lat),long=\(long),name=\(name.trimmingCharacters(in: .whitespacesAndNewlines))"
                showForward = true
            }, label: {
                Image(systemName: "paperplane")
                    .frame(width: 18, height: 18)
                    .font(.headline)
                    .padding(8)
                    .background(.gray.opacity(0.2))
                    .clipShape(Circle())
            })
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                openMaps(lat: lat, long: long, name: name)
            }, label: {
                Image(systemName: "mappin.and.ellipse")
                    .frame(width: 18, height: 18)
                    .font(.headline)
                    .padding(8).foregroundStyle(.blue)
                    .background(.gray.opacity(0.2))
                    .clipShape(Circle())
            })
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                popRoot.alertReason = "Location copied"
                popRoot.alertImage = "link"
                withAnimation {
                    popRoot.showAlert = true
                }
                UIPasteboard.general.string = "https://hustle.page/location/lat=\(lat),long=\(long),name=\(name.trimmingCharacters(in: .whitespacesAndNewlines))"
            }, label: {
                Image(systemName: "link")
                    .frame(width: 18, height: 18)
                    .font(.headline)
                    .padding(8).foregroundStyle(.blue)
                    .background(.gray.opacity(0.2))
                    .clipShape(Circle())
            })
        }
    }
}

func openMaps(lat: Double, long: Double, name: String) {
    let latitude: CLLocationDegrees = lat
    let longitude: CLLocationDegrees = long
    let regionDistance:CLLocationDistance = 10000
    let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
    let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
    let options = [
        MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
        MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
    ]
    let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
    let mapItem = MKMapItem(placemark: placemark)
    mapItem.name = name
    mapItem.openInMaps(launchOptions: options)
}

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @State private var coordinate = CLLocationCoordinate2DMake(45.5202471, -122.6741949)
    let city: String
    let state: String
    let country: String
    let is100: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        let geocoder = CLGeocoder()
        var address = "\(city), \(state), \(country)"
        if state.isEmpty {
            address = "\(city), \(country)"
        }
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let placemark = placemarks?.first, let location = placemark.location {
                self.coordinate = location.coordinate
                mapView.setCenter(self.coordinate, animated: true)
                
                let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: is100 ? 20000 : 10000, longitudinalMeters: is100 ? 20000 : 10000)
                mapView.setRegion(region, animated: true)

                let regionRadius = is100 ? 10000.0 : 3500.0
                let circle = MKCircle(center: coordinate, radius: regionRadius)
                mapView.addOverlay(circle)
            }
        }
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKCircle {
                let circleRenderer = MKCircleRenderer(circle: circle)
                circleRenderer.strokeColor = UIColor.black
                circleRenderer.fillColor = UIColor.green.withAlphaComponent(0.5)
                circleRenderer.lineWidth = 1.0
                return circleRenderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

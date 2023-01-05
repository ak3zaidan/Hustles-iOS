import CoreLocation

class LocationManager: NSObject {
    private var manager: CLLocationManager?
    private var completion: (((String?, String?)) -> Void)?
    private var countriesAdd = ["China", "Japan", "India"]

    override init() {
        super.init()
    }

    func requestLocation(completion: @escaping ((String?, String?)) -> Void) {
        self.completion = completion

        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyKilometer
    }
}

extension LocationManager : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first(where: { $0.horizontalAccuracy <= manager.desiredAccuracy }) ?? locations.last {
            manager.stopUpdatingLocation()
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                var postalCode: String? = nil
                var country: String? = nil
                if error == nil {
                    if let placemark = placemarks?.first {
                        postalCode = placemark.postalCode
                        country = placemark.country
                        
                        if postalCode == nil {
                            if placemark.locality != placemark.administrativeArea {
                                postalCode = (placemark.locality ?? "") + " " + (placemark.administrativeArea ?? "")
                            } else {
                                if let city = placemark.locality ?? placemark.administrativeArea {
                                    postalCode = city
                                }
                            }
                        } else if self.countriesAdd.contains(country ?? ""){
                            postalCode! += " \(placemark.administrativeArea ?? "")"
                        }
                    }
                }
                self.completion?((postalCode, country))
                self.completion = nil
                self.manager = nil
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.completion?((nil, nil))
        self.completion = nil
        self.manager = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager){
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied:
            self.completion?((nil, nil))
            self.completion = nil
            self.manager = nil
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted:
            self.completion?((nil, nil))
            self.completion = nil
            self.manager = nil
        @unknown default:
            manager.requestWhenInUseAuthorization()
        }
    }
}

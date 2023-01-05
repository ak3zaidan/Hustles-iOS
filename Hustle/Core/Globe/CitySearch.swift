import SwiftUI
import MapKit
import CoreLocation

struct CityResult: Identifiable, Hashable {
    var id: String
    var city: String
    var country: String
    var longitude: Double
    var latitude: Double
}

class CitySearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery: String = ""
    @Published var searchResults: [CityResult] = []
    @Published var searching: Bool = false
    @Published var showSearch: Bool = false
    let popularCities: [CityResult] = [
        CityResult(id: "1", city: "Tokyo", country: "Japan", longitude: 139.6917, latitude: 35.6895),
        CityResult(id: "2", city: "New York City", country: "USA", longitude: -74.0060, latitude: 40.7128),
        CityResult(id: "3", city: "Paris", country: "France", longitude: 2.3522, latitude: 48.8566),
        CityResult(id: "4", city: "London", country: "United Kingdom", longitude: -0.1276, latitude: 51.5074),
        CityResult(id: "5", city: "Dubai", country: "UAE", longitude: 55.2708, latitude: 25.2769),
        CityResult(id: "6", city: "Beijing", country: "China", longitude: 116.4074, latitude: 39.9042),
        CityResult(id: "7", city: "Los Angeles", country: "USA", longitude: -118.2437, latitude: 34.0522),
        CityResult(id: "8", city: "Singapore", country: "Singapore", longitude: 103.8198, latitude: 1.3521),
        CityResult(id: "9", city: "Istanbul", country: "Turkey", longitude: 28.9784, latitude: 41.0082),
        CityResult(id: "10", city: "Mumbai", country: "India", longitude: 72.8777, latitude: 19.0760)
    ]
    
    private var searchCompleter: MKLocalSearchCompleter!
    
    override init() {
        super.init()
        
        searchCompleter = MKLocalSearchCompleter()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }
    
    func makeCityCanidates(){
        if searchQuery.isEmpty || searchResults.isEmpty {
            popularCities.forEach { element in
                if !searchResults.contains(where: { $0.city == element.city && $0.country == $0.country }) {
                    searchResults.append(element)
                }
            }
        }
    }
    
    func sortSearch(){
        DispatchQueue.main.async {
            self.searchResults = self.searchResults.sorted { (place1, place2) in
                let score1 = self.score(for: place1, searchStr: self.searchQuery)
                let score2 = self.score(for: place2, searchStr: self.searchQuery)
                return score1 > score2
            }
        }
    }
    
    func sortCustomSearch(searchSTR: String){
        DispatchQueue.main.async {
            self.searchResults = self.searchResults.sorted { (place1, place2) in
                let score1 = self.score(for: place1, searchStr: searchSTR)
                let score2 = self.score(for: place2, searchStr: searchSTR)
                return score1 > score2
            }
        }
    }
    
    func score(for place: CityResult, searchStr: String) -> Int {
        let cityMatch = place.city.lowercased().contains(searchStr.lowercased()) ? 2 : 0
        let countryMatch = place.country.lowercased().contains(searchStr.lowercased()) ? 1 : 0
        return cityMatch + countryMatch
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searching = true
        getCityList(results: completer.results) { cityResults in
            DispatchQueue.main.async {
                self.searching = false
                cityResults.forEach { element in
                    if !self.searchResults.contains(where: { $0.city == element.city && $0.country == element.country }) {
                        self.searchResults.insert(element, at: 0)
                    }
                }
                self.sortSearch()
            }
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) { }
    
    func performSearch() {
        searchCompleter.queryFragment = searchQuery
    }
    func performCustomSearch(query: String) {
        searchCompleter.queryFragment = query
    }
    
    private func getCityList(results: [MKLocalSearchCompletion], completion: @escaping ([CityResult]) -> Void) {
        var searchResults: [CityResult] = []
        let dispatchGroup = DispatchGroup()
        
        for result in results {
            dispatchGroup.enter()
            
            let request = MKLocalSearch.Request(completion: result)
            let search = MKLocalSearch(request: request)
            
            search.start { (response, error) in
                defer {
                    dispatchGroup.leave()
                }
                
                guard let response = response else { return }
                
                for item in response.mapItems {
                    if let location = item.placemark.location {
                        
                        let city = item.placemark.locality ?? ""
                        var country = item.placemark.country ?? ""
                        if country.isEmpty {
                            country = item.placemark.countryCode ?? ""
                        }
                        
                        if !city.isEmpty {
                            let cityResult = CityResult(id: "\(UUID())", city: city, country: country, longitude: location.coordinate.longitude, latitude: location.coordinate.latitude)
                            searchResults.append(cityResult)
                        }
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(searchResults)
        }
    }
}

class GlobeLocationManager: NSObject {
    private var manager: CLLocationManager?
    private var completion: (((String, String, Double, Double, String)) -> Void)?
  
    override init() {
        super.init()
    }

    func requestLocation(completion: @escaping ((String, String, Double, Double, String)) -> Void) {
        self.completion = completion

        manager = CLLocationManager()
        manager?.delegate = self
    
        switch manager?.accuracyAuthorization {
        case .fullAccuracy:
            manager?.desiredAccuracy = kCLLocationAccuracyBest
        case .reducedAccuracy:
            manager?.desiredAccuracy = kCLLocationAccuracyReduced
        case .none:
            manager?.desiredAccuracy = kCLLocationAccuracyReduced
        @unknown default:
            manager?.desiredAccuracy = kCLLocationAccuracyReduced
        }
    }
}

extension GlobeLocationManager : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first(where: { $0.horizontalAccuracy <= manager.desiredAccuracy }) ?? locations.last {
            manager.stopUpdatingLocation()
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                var city = ""
                var country = ""
                var state = ""
                var lat = 0.0
                var long = 0.0
             
                if let placemark = placemarks?.first {
                    city = placemark.locality ?? ""
                    country = placemark.country ?? ""
                    lat = placemark.location?.coordinate.latitude ?? 0.0
                    long = placemark.location?.coordinate.longitude ?? 0.0
                    if let st = placemark.administrativeArea {
                        state = (st == city) ? "" : st
                    }
                }
                if lat == 0.0 {
                    lat = location.coordinate.latitude
                }
                if long == 0.0 {
                    long = location.coordinate.longitude
                }
                
                self.completion?((city, country, lat, long, state))
                self.completion = nil
                self.manager = nil
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.completion?(("", "", 0.0, 0.0, ""))
        self.completion = nil
        self.manager = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager){
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied:
            self.completion?(("", "", 0.0, 0.0, ""))
            self.completion = nil
            self.manager = nil
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted:
            self.completion?(("", "", 0.0, 0.0, ""))
            self.completion = nil
            self.manager = nil
        @unknown default:
            manager.requestWhenInUseAuthorization()
        }
    }
}

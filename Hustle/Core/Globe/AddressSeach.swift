import SwiftUI
import MapKit
import CoreLocation

class AddressSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchResults: [searchLoc] = []
    @Published var searching: Bool = false
    private var searchCompleter: MKLocalSearchCompleter!
    
    override init() {
        super.init()
        
        searchCompleter = MKLocalSearchCompleter()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        getCityList(results: completer.results) { cityResults in
            DispatchQueue.main.async {
                self.searching = false
                cityResults.forEach { element in
                    if !self.searchResults.contains(where: { $0.searchName == element.searchName }) {
                        self.searchResults.insert(element, at: 0)
                    }
                }
            }
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) { }
    
    func performSearch(queryStr: String) {
        searching = true
        self.searchCompleter.queryFragment = queryStr
    }
    
    private func getCityList(results: [MKLocalSearchCompletion], completion: @escaping ([searchLoc]) -> Void) {
        var searchTemp: [searchLoc] = []
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
                    print(item)
                    if let name = item.name {
                        searchTemp.append(searchLoc(searchName: name, lat: item.placemark.coordinate.latitude, long: item.placemark.coordinate.longitude))
                    }
                }
            }
        }
        dispatchGroup.notify(queue: .main) {
            completion(searchTemp)
        }
    }
}

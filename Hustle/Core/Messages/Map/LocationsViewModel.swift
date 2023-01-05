import MapKit
import SwiftUI
import NetworkExtension

func isVPNConnected() -> Bool {
    let vpnStatus = NEVPNManager.shared().connection.status
    switch vpnStatus {
    case .connected, .connecting:
        return true
    default:
        return false
    }
}

struct mainBusiness: Identifiable {
    let id: String = UUID().uuidString
    let coordinates: CLLocationCoordinate2D
    var business: Business
    var tag: String
    var distanceFromMe: Double
    var triedToFetchDetails: Bool?
    var timeDistance: String?
}

class LocationsViewModel: ObservableObject {
    @Published var allRestaurants: [mainBusiness] = []
    @Published var searchingPlaces: Bool = false
    @Published var searchingNav: Bool = false
    @Published var couldntLoadRestraunts: Int = 0   //if 0 no error, if 1 then error but retry, if 2 dont retry
    let tags = ["Restaurants", "Cafes", "Parks", "Ice Cream"]
    
    @Published var locations: [LocationMap] = []
    var tempRemoveLocations: [LocationMap] = []
    @Published var stories: [LocationMap] = []
    @Published var regionStories: [LocationMap] = []
    @Published var memories: [LocationMap] = []
    @Published var mapLocation: LocationMap? = nil
    @Published var mapGroup: groupLocation? = nil
    @Published var selectedPin: chatPins? = nil
    @Published var selectedBus: mainBusiness? = nil
    @Published var selectedTag: String = "Restaurants"
    @Published var multiBusiness: [String] = []
    @Published var mapCameraPosition = MapCameraPosition.automatic
    let mapSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    @Published var preventCenter: Bool = false
    @Published var runVPNError: Bool = false
    @Published var recommendError: Bool = false
    @Published var gotData: Bool = false
    var lastUserUpdate: Date? = nil
    var fetchedMemories: Bool = false
    
    func allMatches() -> [mainBusiness] {
        var final: [mainBusiness] = []
        allRestaurants.forEach { element in
            if element.tag == selectedTag {
                final.append(element)
            }
        }
         return final
    }
    func orderPlaces(query: String) {
        self.allRestaurants = self.allRestaurants.sorted {
            scoreBusiness($0.business, query: query) > scoreBusiness($1.business, query: query)
        }
    }
    func scoreBusiness(_ business: Business, query: String) -> Int {
        var score = 0
        let lowercasedQuery = query.lowercased()
        
        if let name = business.name?.lowercased() {
            if name.contains(lowercasedQuery) {
                score += 100
            } else {
                score += name.split(separator: " ").filter { $0.starts(with: lowercasedQuery) }.count * 10
            }
        }
        if let categories = business.categories {
            for category in categories {
                if let title = category.title?.lowercased() {
                    if title.contains(lowercasedQuery) {
                        score += 50
                    }
                }
            }
        }
        return score
    }
    func getRestaurantDetailsYelpRowView(currentLoc: CLLocationCoordinate2D, id: String, completion: @escaping(mainBusiness?) -> Void) {
        guard let url = URL(string: "https://api.yelp.com/v3/businesses/\(id)") else { return }
        var urlRequest = URLRequest(url: url)
        let key = "rBQ40KuuD_7h8gI0kgy6k-5-cVyo5lCPYL-PbcuWvJRdex6UHBgK9TjP0kIBL9eFKPuLlZi46VrdzT535ahhrKiLrQZZj0nGV46p2mo6XO6v2hNu81qKw7W1lZS_ZnYx"
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let data = data {
                let jsonDecoder = JSONDecoder()
                do {
                    let business = try jsonDecoder.decode(Business.self, from: data)
                    DispatchQueue.main.async {
                        if !self.allRestaurants.contains(where: { $0.business.id == id }) {
                            if let coord = business.coordinates?.clLocationCoordinate2D {
                                let coordinate1 = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                                let coordinate2 = CLLocation(latitude: currentLoc.latitude, longitude: currentLoc.longitude)
                                let distanceInMeters = coordinate1.distance(from: coordinate2)
                                let distanceInMiles = distanceInMeters / 1609.344
                                let roundedDistanceInMiles = (distanceInMiles * 10).rounded() / 10
                                let new = mainBusiness(coordinates: coord, business: business, tag: "", distanceFromMe: roundedDistanceInMiles)
                                self.allRestaurants.append(new)
                                completion(new)
                            } else {
                                let new = mainBusiness(coordinates: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), business: business, tag: "", distanceFromMe: 1.0)
                                self.allRestaurants.append(new)
                                completion(new)
                            }
                        }
                    }
                } catch {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }.resume()
    }
    func getRestaurantDetails(id: String) {
        guard let url = URL(string: "https://api.yelp.com/v3/businesses/\(id)") else { return }
        var urlRequest = URLRequest(url: url)
        let key = "rBQ40KuuD_7h8gI0kgy6k-5-cVyo5lCPYL-PbcuWvJRdex6UHBgK9TjP0kIBL9eFKPuLlZi46VrdzT535ahhrKiLrQZZj0nGV46p2mo6XO6v2hNu81qKw7W1lZS_ZnYx"
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        
        if let index = self.allRestaurants.firstIndex(where: { $0.business.id == id }) {
            self.allRestaurants[index].triedToFetchDetails = true
        }

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let data = data {
                let jsonDecoder = JSONDecoder()
                do {
                    let detailedRestaurant = try jsonDecoder.decode(Business.self, from: data)
                    DispatchQueue.main.async {
                        if let index = self.allRestaurants.firstIndex(where: { $0.business.id == id }) {
                            var existingRestaurant = self.allRestaurants[index]
                            existingRestaurant.business.merge(with: detailedRestaurant)
                            self.allRestaurants[index] = existingRestaurant
                            if self.selectedBus?.business.id == existingRestaurant.business.id {
                                self.selectedBus = existingRestaurant
                            }
                        }
                    }
                } catch {
                    self.runVPNError.toggle()
                }
            } else {
                self.runVPNError.toggle()
            }
        }.resume()
    }
    func loadRestraunts(currentLoc: CLLocationCoordinate2D, query: String) {
        if !allRestaurants.contains(where: { $0.tag.lowercased() == query.lowercased() }) && couldntLoadRestraunts < 3 {
            searchingPlaces = true
            let allCoord = Array(locations.map({ $0.coordinates }).dropFirst())
            let coord = self.center(locations: allCoord, removeOutliers: true).0
            
            guard let url = URL(string: "https://api.yelp.com/v3/businesses/search?term=\(query.lowercased())&latitude=\(coord.latitude)&longitude=\(coord.longitude)") else { return }
            var urlRequest = URLRequest(url: url)
            let key = "rBQ40KuuD_7h8gI0kgy6k-5-cVyo5lCPYL-PbcuWvJRdex6UHBgK9TjP0kIBL9eFKPuLlZi46VrdzT535ahhrKiLrQZZj0nGV46p2mo6XO6v2hNu81qKw7W1lZS_ZnYx"
            urlRequest.httpMethod = "GET"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                DispatchQueue.main.async {
                    if let data = data {
                        let jsonDecoder = JSONDecoder()
                        do {
                            let parsedJson = try jsonDecoder.decode(Businesses.self, from: data)
                            let isEmpty = self.allRestaurants.isEmpty
                            for business in parsedJson.businesses {
                                if let coord = business.coordinates?.clLocationCoordinate2D {
                                    let coordinate1 = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                                    let coordinate2 = CLLocation(latitude: currentLoc.latitude, longitude: currentLoc.longitude)
                                    let distanceInMeters = coordinate1.distance(from: coordinate2)
                                    let distanceInMiles = distanceInMeters / 1609.344
                                    let roundedDistanceInMiles = (distanceInMiles * 10).rounded() / 10
                                    self.allRestaurants.append(mainBusiness(coordinates: coord, business: business, tag: query, distanceFromMe: roundedDistanceInMiles))
                                }
                            }
                            self.gotData.toggle()
                            if isEmpty && !self.allRestaurants.isEmpty {
                                self.searchingNav.toggle()
                            }
                        } catch {
                            self.gotData.toggle()
                            self.recommendError.toggle()
                            self.runVPNError.toggle()
                            self.couldntLoadRestraunts += 1
                        }
                    } else {
                        self.gotData.toggle()
                        self.recommendError.toggle()
                        self.runVPNError.toggle()
                        self.couldntLoadRestraunts += 1
                    }
                    self.searchingPlaces = false
                }
            }.resume()
        }
    }
    func setMapPosition(animate: Bool, isStory: Bool) {
        var allCoord: [CLLocationCoordinate2D] = []
        if isStory {
            allCoord = Array(stories.map({ $0.coordinates }).dropFirst())
        } else {
            allCoord = Array(locations.map({ $0.coordinates }).dropFirst())
        }
        if allCoord.isEmpty {
            return
        }
        let region = self.center(locations: allCoord, removeOutliers: true)
        if animate {
            preventCenter = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.preventCenter = false
            }
            withAnimation(.easeIn(duration: 0.1)){
                mapCameraPosition = .region(MKCoordinateRegion(center: region.0, span: region.1))
            }
        } else {
            mapCameraPosition = .region(MKCoordinateRegion(center: region.0, span: region.1))
        }
    }
    func setPlaceMemPosition(animate: Bool, isMemory: Bool) {
        var allCoord: [CLLocationCoordinate2D] = []
        if isMemory {
            allCoord = Array(memories.map({ $0.coordinates }).dropFirst())
        } else {
            let temp = allMatches()
            allCoord = temp.compactMap({ $0.coordinates })
        }
        if allCoord.isEmpty {
            return
        }
        let region = self.center(locations: allCoord, removeOutliers: true)
        if animate {
            preventCenter = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.preventCenter = false
            }
            withAnimation(.easeIn(duration: 0.1)){
                mapCameraPosition = .region(MKCoordinateRegion(center: region.0, span: region.1))
            }
        } else {
            mapCameraPosition = .region(MKCoordinateRegion(center: region.0, span: region.1))
        }
    }
    func setPinPosition(coords: [CLLocationCoordinate2D]) {
        let region = self.center(locations: coords, removeOutliers: true)
        preventCenter = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.preventCenter = false
        }
        withAnimation(.easeIn(duration: 0.1)){
            mapCameraPosition = .region(MKCoordinateRegion(center: region.0, span: region.1))
        }
    }
    func showNextLocation(location: LocationMap, lat: CGFloat, long: CGFloat) {
        withAnimation(.easeInOut(duration: 0.1)) {
            selectedPin = nil
            mapGroup = nil
            mapLocation = location
            mapCameraPosition = .region(MKCoordinateRegion(
                center: location.coordinates,
                span: MKCoordinateSpan(latitudeDelta: lat, longitudeDelta: long)))
        }
    }
    func showNextPlace(location: mainBusiness, lat: CGFloat, long: CGFloat) {
        withAnimation(.easeInOut(duration: 0.1)) {
            selectedPin = nil
            mapGroup = nil
            selectedBus = location
            mapCameraPosition = .region(MKCoordinateRegion(
                center: location.coordinates,
                span: MKCoordinateSpan(latitudeDelta: lat, longitudeDelta: long)))
        }
    }
    func center(locations: [CLLocationCoordinate2D], removeOutliers: Bool, threshold: Double = 200) -> (CLLocationCoordinate2D, MKCoordinateSpan) {
        guard !locations.isEmpty else {
            return (CLLocationCoordinate2D(latitude: 0, longitude: 0), MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        }
        
        func isWithinDistanceThreshold(location1: CLLocationCoordinate2D, location2: CLLocationCoordinate2D, thresholdMiles: Double) -> Bool {
            let coordinate1 = CLLocation(latitude: location1.latitude, longitude: location1.longitude)
            let coordinate2 = CLLocation(latitude: location2.latitude, longitude: location2.longitude)
            
            let distanceInMeters = coordinate1.distance(from: coordinate2)
            let distanceInMiles = distanceInMeters / 1609.0 // Convert meters to miles
            
            return distanceInMiles <= thresholdMiles
        }

        // Calculate the mean coordinate (not the geometric mean)
        let meanLatitude = locations.map { $0.latitude }.reduce(0, +) / Double(locations.count)
        let meanLongitude = locations.map { $0.longitude }.reduce(0, +) / Double(locations.count)
        let meanLocation = CLLocationCoordinate2D(latitude: meanLatitude, longitude: meanLongitude)

        if removeOutliers {
            // Filter out locations that are further than the threshold distance from the mean
            let filteredLocations = locations.filter { location in
                isWithinDistanceThreshold(location1: meanLocation, location2: location, thresholdMiles: threshold)
            }

            if !filteredLocations.isEmpty {
                // Recalculate the bounding box center for filtered locations
                let maxLatitude = filteredLocations.map { $0.latitude }.max() ?? 0
                let minLatitude = filteredLocations.map { $0.latitude }.min() ?? 0
                let maxLongitude = filteredLocations.map { $0.longitude }.max() ?? 0
                let minLongitude = filteredLocations.map { $0.longitude }.min() ?? 0
                
                var latitudeDelta = maxLatitude - minLatitude
                var longitudeDelta = maxLongitude - minLongitude
                
                let minimumSpan: CLLocationDegrees = 0.05
                latitudeDelta = max(latitudeDelta, minimumSpan) * 1.55
                longitudeDelta = max(longitudeDelta, minimumSpan) * 1.55

                return (CLLocationCoordinate2D(
                    latitude: (maxLatitude + minLatitude) / 2,
                    longitude: (maxLongitude + minLongitude) / 2
                ), MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
            }
        }

        // Calculate the bounding box center if no outliers are removed
        let maxLatitude = locations.map { $0.latitude }.max() ?? 0
        let minLatitude = locations.map { $0.latitude }.min() ?? 0
        let maxLongitude = locations.map { $0.longitude }.max() ?? 0
        let minLongitude = locations.map { $0.longitude }.min() ?? 0
        
        var latitudeDelta = maxLatitude - minLatitude
        var longitudeDelta = maxLongitude - minLongitude
        
        let minimumSpan: CLLocationDegrees = 0.001
        latitudeDelta = max(latitudeDelta, minimumSpan) * 1.55
        longitudeDelta = max(longitudeDelta, minimumSpan) * 1.55

        return (CLLocationCoordinate2D(
            latitude: (maxLatitude + minLatitude) / 2,
            longitude: (maxLongitude + minLongitude) / 2
        ), MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
    }
    func getMinSpan(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateSpan {
        var minLatitude: CLLocationDegrees = coordinates.first!.latitude
        var maxLatitude: CLLocationDegrees = coordinates.first!.latitude
        var minLongitude: CLLocationDegrees = coordinates.first!.longitude
        var maxLongitude: CLLocationDegrees = coordinates.first!.longitude
        
        for coordinate in coordinates {
            if coordinate.latitude < minLatitude { minLatitude = coordinate.latitude }
            if coordinate.latitude > maxLatitude { maxLatitude = coordinate.latitude }
            if coordinate.longitude < minLongitude { minLongitude = coordinate.longitude }
            if coordinate.longitude > maxLongitude { maxLongitude = coordinate.longitude }
        }
  
        var latitudeDelta = maxLatitude - minLatitude
        var longitudeDelta = maxLongitude - minLongitude
        
        let minimumSpan: CLLocationDegrees = 0.001
        latitudeDelta = max(latitudeDelta, minimumSpan) * 1.5
        longitudeDelta = max(longitudeDelta, minimumSpan) * 1.5
        
        return MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
    }
    func setMapRegion(group: groupLocation, oldLat: CGFloat, oldLong: CGFloat) {
        let coordinates = group.allLocs.map({ $0.coordinates })
        
        guard !coordinates.isEmpty else { return }
        var minLatitude: CLLocationDegrees = coordinates.first!.latitude
        var maxLatitude: CLLocationDegrees = coordinates.first!.latitude
        var minLongitude: CLLocationDegrees = coordinates.first!.longitude
        var maxLongitude: CLLocationDegrees = coordinates.first!.longitude
        
        for coordinate in coordinates {
            if coordinate.latitude < minLatitude { minLatitude = coordinate.latitude }
            if coordinate.latitude > maxLatitude { maxLatitude = coordinate.latitude }
            if coordinate.longitude < minLongitude { minLongitude = coordinate.longitude }
            if coordinate.longitude > maxLongitude { maxLongitude = coordinate.longitude }
        }
        
        let centerLatitude = (minLatitude + maxLatitude) / 2
        let centerLongitude = (minLongitude + maxLongitude) / 2
        let centerCoordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)

        var latitudeDelta = maxLatitude - minLatitude
        var longitudeDelta = maxLongitude - minLongitude
        
        let minimumSpan: CLLocationDegrees = 0.005
        latitudeDelta = max(latitudeDelta, minimumSpan) * 1.5
        longitudeDelta = max(longitudeDelta, minimumSpan) * 1.5
        
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)
        
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.1)) {
            selectedPin = nil
            mapLocation = nil
            multiBusiness = []
            selectedBus = nil
            mapCameraPosition = .region(region)
        }
        if areAllLocationsWithin300Yards(from: coordinates) || oldLat <= latitudeDelta && oldLong <= longitudeDelta {
            withAnimation(.easeInOut(duration: 0.1)) {
                mapGroup = group
            }
        }
    }
    func setPlaceRegion(group: groupBusiness, oldLat: CGFloat, oldLong: CGFloat, completion: @escaping(Bool) -> Void) {
        let coordinates = group.allLocs.compactMap { $0.coordinates?.clLocationCoordinate2D }
        
        guard !coordinates.isEmpty else { return }
        var minLatitude: CLLocationDegrees = coordinates.first!.latitude
        var maxLatitude: CLLocationDegrees = coordinates.first!.latitude
        var minLongitude: CLLocationDegrees = coordinates.first!.longitude
        var maxLongitude: CLLocationDegrees = coordinates.first!.longitude
        
        for coordinate in coordinates {
            if coordinate.latitude < minLatitude { minLatitude = coordinate.latitude }
            if coordinate.latitude > maxLatitude { maxLatitude = coordinate.latitude }
            if coordinate.longitude < minLongitude { minLongitude = coordinate.longitude }
            if coordinate.longitude > maxLongitude { maxLongitude = coordinate.longitude }
        }
        
        let centerLatitude = (minLatitude + maxLatitude) / 2
        let centerLongitude = (minLongitude + maxLongitude) / 2
        let centerCoordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)

        var latitudeDelta = maxLatitude - minLatitude
        var longitudeDelta = maxLongitude - minLongitude
        
        let minimumSpan: CLLocationDegrees = 0.001
        latitudeDelta = max(latitudeDelta, minimumSpan) * 1.5
        longitudeDelta = max(longitudeDelta, minimumSpan) * 1.5
        
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)
        
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        withAnimation(.easeInOut(duration: 0.1)) {
            selectedPin = nil
            mapLocation = nil
            mapGroup = nil
            mapCameraPosition = .region(region)
        }
        if areAllLocationsWithin300Yards(from: coordinates, yards: 300.0) || oldLat <= latitudeDelta && oldLong <= longitudeDelta {
            multiBusiness = group.allLocs.compactMap { $0.id }
            completion(!multiBusiness.isEmpty)
        } else {
            completion(false)
        }
    }
    func setStoryRegion(group: groupLocation, oldLat: CGFloat, oldLong: CGFloat, completion: @escaping(Bool) -> Void) {
        let coordinates = group.allLocs.map({ $0.coordinates })
        
        guard !coordinates.isEmpty else { return }
        var minLatitude: CLLocationDegrees = coordinates.first!.latitude
        var maxLatitude: CLLocationDegrees = coordinates.first!.latitude
        var minLongitude: CLLocationDegrees = coordinates.first!.longitude
        var maxLongitude: CLLocationDegrees = coordinates.first!.longitude
        
        for coordinate in coordinates {
            if coordinate.latitude < minLatitude { minLatitude = coordinate.latitude }
            if coordinate.latitude > maxLatitude { maxLatitude = coordinate.latitude }
            if coordinate.longitude < minLongitude { minLongitude = coordinate.longitude }
            if coordinate.longitude > maxLongitude { maxLongitude = coordinate.longitude }
        }
        
        let centerLatitude = (minLatitude + maxLatitude) / 2
        let centerLongitude = (minLongitude + maxLongitude) / 2
        let centerCoordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)

        var latitudeDelta = maxLatitude - minLatitude
        var longitudeDelta = maxLongitude - minLongitude
        
        if areAllLocationsWithin300Yards(from: coordinates, yards: 1760.0) || oldLat <= latitudeDelta && oldLong <= longitudeDelta {
            completion(true)
            return
        }
        
        let minimumSpan: CLLocationDegrees = 0.001
        latitudeDelta = max(latitudeDelta, minimumSpan) * 1.5
        longitudeDelta = max(longitudeDelta, minimumSpan) * 1.5
        
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)
        
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        withAnimation(.easeInOut) {
            selectedPin = nil
            mapLocation = nil
            multiBusiness = []
            selectedBus = nil
            mapCameraPosition = .region(region)
        }
        completion(false)
    }
}

struct LocationMap: Identifiable, Equatable {
    var id: String = UUID().uuidString
    var coordinates: CLLocationCoordinate2D
    var shouldShowName = false
    var shouldShowBattery = false
    var user: User?
    var story: Story?
    var memory: Memory?
    var preview: UIImage?
    var lastUpdated: Date?
    var timeDistance: String?
    var infoString: String?
    var placeString: String?
    var triedToGetStories = false
    var userStories: [LocationMap]? = nil
        
    static func == (lhs: LocationMap, rhs: LocationMap) -> Bool {
        lhs.id == rhs.id
    }
}

struct groupLocation: Identifiable {
    let id: String = UUID().uuidString
    var coordinates: CLLocationCoordinate2D
    var allLocs: [LocationMap]
    var shouldShowName = false
}

struct groupBusiness: Identifiable {
    let id: String = UUID().uuidString
    var name: String
    var photos: [String]
    var coordinates: CLLocationCoordinate2D
    var allLocs: [Business]
}

func degreesToRadians(_ degrees: Double) -> Double {
    return degrees * .pi / 180
}

func areCoordinatesMoreThan100FeetApart(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Bool {
    let earthRadius = 6371000.0
    
    let lat1Rad = degreesToRadians(lat1)
    let lon1Rad = degreesToRadians(lon1)
    let lat2Rad = degreesToRadians(lat2)
    let lon2Rad = degreesToRadians(lon2)
    
    let deltaLat = lat2Rad - lat1Rad
    let deltaLon = lon2Rad - lon1Rad
    
    let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
            cos(lat1Rad) * cos(lat2Rad) *
            sin(deltaLon / 2) * sin(deltaLon / 2)
    let c = 2 * atan2(sqrt(a), sqrt(1 - a))
    let distanceInMeters = earthRadius * c
    let distanceInFeet = distanceInMeters * 3.28084
    
    // Return whether the distance is greater than 50 feet
    return distanceInFeet > 100
}

func distanceBetween(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> Double {
    let earthRadiusMeters: Double = 6371000 // Earth's radius in meters

    let deltaLatitude = (coord2.latitude - coord1.latitude).degreesToRadians
    let deltaLongitude = (coord2.longitude - coord1.longitude).degreesToRadians

    let a = sin(deltaLatitude / 2) * sin(deltaLatitude / 2) +
            cos(coord1.latitude.degreesToRadians) * cos(coord2.latitude.degreesToRadians) *
            sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
    let c = 2 * atan2(sqrt(a), sqrt(1 - a))

    return earthRadiusMeters * c
}

func areAllLocationsWithin300Yards(from coordinates: [CLLocationCoordinate2D], yards: Double = 300.0) -> Bool {
    let maxDistanceMeters: Double = yards * 0.9144 // Convert yards to meters

    for i in 0..<coordinates.count {
        for j in (i + 1)..<coordinates.count {
            let distance = distanceBetween(coordinates[i], coordinates[j])
            if distance > maxDistanceMeters {
                return false
            }
        }
    }
    return true
}

extension CLLocationDegrees {
    var degreesToRadians: Double { return self * .pi / 180 }
}

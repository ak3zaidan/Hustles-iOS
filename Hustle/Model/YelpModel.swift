import Foundation
import CoreLocation

struct Businesses: Codable {
    let businesses: [Business]
}

struct Business: Codable, Hashable, Identifiable {
    var rating: Double?
    var price: String?
    var phone: String?
    var id: String?
    var categories: [Category]?
    var review_count: Int?
    var name: String?
    var url: String?
    var coordinates: Coordinates?
    var image_url: String?
    var location: LocationYelp?
    var hours: [Hours]?
    var photos: [String]?
}

struct Category: Codable, Hashable {
    let alias: String?
    let title: String?
}

struct Coordinates: Codable, Hashable {
    let latitude: Double?
    let longitude: Double?
    
    var clLocationCoordinate2D: CLLocationCoordinate2D? {
        guard let latitude = latitude, let longitude = longitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct LocationYelp: Codable, Hashable {
    let city: String?
    let country: String?
    let address2: String?
    let address3: String?
    let state: String?
    let address1: String?
    let zip_code: String?
}

struct Hours: Codable, Hashable {
    let hours_type: String?
    let open: [Open]?
    let is_open_now: Bool?
}

struct Open: Codable, Hashable {
    let is_overnight: Bool?
    let end: String?
    let day: Int?
    let start: String?
}

extension Business {
    mutating func merge(with detailedBusiness: Business) {
        if self.rating == nil, let rating = detailedBusiness.rating {
            self.rating = rating
        }
        if self.price == nil, let price = detailedBusiness.price {
            self.price = price
        }
        if self.phone == nil, let phone = detailedBusiness.phone {
            self.phone = phone
        }
        if self.categories == nil, let categories = detailedBusiness.categories {
            self.categories = categories
        }
        if self.review_count == nil, let review_count = detailedBusiness.review_count {
            self.review_count = review_count
        }
        if self.url == nil, let url = detailedBusiness.url {
            self.url = url
        }
        if self.coordinates == nil, let coordinates = detailedBusiness.coordinates {
            self.coordinates = coordinates
        }
        if self.image_url == nil, let image_url = detailedBusiness.image_url {
            self.image_url = image_url
        }
        if self.location == nil, let location = detailedBusiness.location {
            self.location = location
        }
        if self.hours == nil, let hours = detailedBusiness.hours {
            self.hours = hours
        }
        if self.photos == nil, let photos = detailedBusiness.photos {
            self.photos = photos
        }
    }
}

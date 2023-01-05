import Foundation
import CoreLocation
import FirebaseFirestore
import Firebase
import SwiftUI

struct ShopPlaces: Identifiable {
    let id: String
    var Country: String
    var state: String
    var city: String
    var possible_locs: [(String, Timestamp?, Bool, [String])]
    var display: [Shop]
    var holder: [Shop]
    var tags: [(String, [Shop])]
}

class ShopViewModel: ObservableObject {
    let geocoder = CLGeocoder()
    let service = ShopService()
    @Published var shopContent = [ShopPlaces]()
    @Published var setState = ""
    @Published var setCity = ""
    @Published var setCountry = ""
    @Published var no_results = false
    
    @Published var selectedCategory: String = "all"
    @Published var shopSort: MenuOption? = MenuOption(option: "Closest first")
    
    func start(zipCode: String, country: String){
        if !setCountry.isEmpty && !setCity.isEmpty {
            if let x = shopContent.firstIndex(where: { $0.Country == setCountry && $0.state == setState && $0.city == setCity }) {
                if x != 0 {
                    let elementToMove = shopContent.remove(at: x)
                    shopContent.insert(elementToMove, at: 0)
                }
                startSecond(byPass: false)
            } else {
                let newElement = ShopPlaces(id: "\(UUID())", Country: setCountry, state: setState, city: setCity, possible_locs: [], display: [], holder: [], tags: [])
                shopContent.insert(newElement, at: 0)
                startSecond(byPass: false)
            }
        } else {
            if isValidZipCode(zipCode) {
                var geoLoc = zipCode
                if !country.isEmpty { geoLoc = zipCode + " " + country }
                geocoder.geocodeAddressString(geoLoc) { (placemarks, _ ) in
                    if let placemarks = placemarks, let placemark = placemarks.first {
                        self.setState = placemark.administrativeArea ?? ""
                        self.setCity = placemark.locality ?? ""
                        self.setCountry = placemark.country ?? ""
                        self.start(zipCode: zipCode, country: country)
                    } else {
                        self.no_results = true
                    }
                }
            } else {
                self.no_results = true
            }
        }
    }
    func startSecond(byPass: Bool) {
        self.no_results = false
        if let element = shopContent.first {
            if element.display.isEmpty && !byPass {
                service.fetchClose(country: setCountry, state: setState, city: setCity, last: nil as Timestamp?) { shop in
                    if !shop.isEmpty {
                        var temp = shop
                        for i in 0..<temp.count {
                            temp[i].tags = temp[i].tagJoined.split(separator: ",").map { String($0) }
                        }
                        self.shopContent[0].display = temp
                        let new: (String, Timestamp?, Bool, [String]) = (self.setCity, shop.last?.timestamp, shop.count < 28 ? true : false, [])
                        self.shopContent[0].possible_locs.append(new)
                    }
                    if shop.count < 28 || element.possible_locs.isEmpty {
                        self.startSecond(byPass: true)
                    }
                }
            } else if element.possible_locs.count <= 1 {
                for i in 0..<shopContent.count {
                    if ((!setState.isEmpty && shopContent[i].Country == setCountry && shopContent[i].state == setState) || (setState.isEmpty && shopContent[i].Country == setCountry)) && shopContent[i].possible_locs.count > 1 {
                        var temp = shopContent[i].possible_locs
                        temp.removeAll(where: { $0.0 == setCity })
                        shopContent[0].possible_locs.append(contentsOf: temp)
                        
                        var all_Possible = shopContent[i].display + shopContent[i].holder
                        all_Possible.removeAll { element in
                            return shopContent[0].display.contains(element)
                        }
                        shopContent[0].display += all_Possible
                        if shopContent[0].display.count < 20 {
                            self.getClose()
                        }
                        return
                    }
                }
                service.getPossibleLocations(country: setCountry, state: setState) { locations in
                    if !locations.isEmpty {
                        locations.forEach { loc in
                            if !element.possible_locs.contains(where: { $0.0 == loc.place }){
                                let newPlace: (String, Timestamp?, Bool, [String]) = (loc.place, nil, false, [])
                                self.shopContent[0].possible_locs.append(newPlace)
                            }
                        }
                        if element.display.count < 20 {
                            self.getClose()
                        }
                    } else if element.display.isEmpty {
                        self.no_results = true
                    }
                }
            }
        }
    }
    func getClose(){
        no_results = false
        if let element = shopContent.first {
            var x = 0
            for i in 0..<element.possible_locs.count {
                if !element.possible_locs[i].2 {
                    x = i
                    break
                }
            }
            if x > 0 || (x == 0 && !element.possible_locs[0].2) {
                service.fetchClose(country: setCountry, state: setState, city: element.possible_locs[x].0, last: element.possible_locs[x].1) { shop in
                    var temp = shop
                    for i in 0..<temp.count {
                        temp[i].tags = temp[i].tagJoined.split(separator: ",").map { String($0) }
                    }
                    let avoid = self.shopContent[0].display + self.shopContent[0].holder
                    temp.removeAll { element in
                        return avoid.contains(element)
                    }
                    self.shopContent[0].display += temp
                    if temp.count < 28 {
                        self.shopContent[0].possible_locs[x].2 = true
                        self.getClose()
                    } else {
                        self.shopContent[0].possible_locs[x].1 = temp.last?.timestamp
                    }
                }
            } else if shopContent[0].display.isEmpty {
                no_results = true
            }
        }
    }
    func getTag(tagName: String, pass: Bool, totalGot: Int){
        no_results = false
        if let element = shopContent.first {
            if tagName == "all" {
                let temp = shopContent[0].display + shopContent[0].holder
                shopContent[0].display = temp
                shopContent[0].holder = []
                if temp.isEmpty { no_results = true }
            } else {
                if !pass {
                    let temp = element.display + element.holder
                    var has: [Shop] = []
                    var doesnt: [Shop] = []
                    for shop in temp {
                        if shop.tagJoined.contains(tagName) {
                            has.append(shop)
                        } else {
                            doesnt.append(shop)
                        }
                    }
                    shopContent[0].display = has
                    shopContent[0].holder = doesnt
                }
                if totalGot < 25 {
                    var x = 0
                    for i in 0..<element.possible_locs.count {
                        if !element.possible_locs[i].2 && !element.possible_locs[i].3.contains(tagName){
                            x = i
                            break
                        }
                    }
                    if x > 0 {
                        service.getTag(country: setCountry, state: setState, city: setCity, tag: tagName) { shop in
                            var temp = shop
                            for i in 0..<temp.count {
                                temp[i].tags = temp[i].tagJoined.split(separator: ",").map { String($0) }
                            }
                            let avoid = self.shopContent[0].display + self.shopContent[0].holder
                            temp.removeAll { element in
                                return avoid.contains(element)
                            }
                            self.shopContent[0].display += temp
                            self.shopContent[0].possible_locs[x].3.append(tagName)
                            if temp.count < 28 {
                                self.shopContent[0].possible_locs[x].2 = true
                                if (totalGot + temp.count) < 25 {
                                    self.getTag(tagName: tagName, pass: true, totalGot: totalGot + temp.count)
                                }
                            } else {
                                self.shopContent[0].possible_locs[x].1 = temp.last?.timestamp
                            }
                        }
                    } else if let first = element.possible_locs.first, x == 0 && !first.2 && !first.3.contains(tagName) {
                        service.getTag(country: setCountry, state: setState, city: setCity, tag: tagName) { shop in
                            var temp = shop
                            for i in 0..<temp.count {
                                temp[i].tags = temp[i].tagJoined.split(separator: ",").map { String($0) }
                            }
                            let avoid = self.shopContent[0].display + self.shopContent[0].holder
                            temp.removeAll { element in
                                return avoid.contains(element)
                            }
                            self.shopContent[0].display += temp
                            self.shopContent[0].possible_locs[x].3.append(tagName)
                            if temp.count < 28 {
                                self.shopContent[0].possible_locs[x].2 = true
                                if (totalGot + temp.count) < 25 {
                                    self.getTag(tagName: tagName, pass: true, totalGot: totalGot + temp.count)
                                }
                            } else {
                                self.shopContent[0].possible_locs[x].1 = temp.last?.timestamp
                            }
                        }
                    } else if shopContent[0].display.isEmpty {
                        no_results = true
                    }
                }
            }
        }
    }
    func refresh(zipCode: String, country: String){
        if shopContent.first != nil {
            if isValidZipCode(zipCode) {
                var geoLoc = zipCode
                if !country.isEmpty { geoLoc = zipCode + " " + country }
                geocoder.geocodeAddressString(geoLoc) { (placemarks, _ ) in
                    if let placemarks = placemarks, let placemark = placemarks.first {
                        let state = placemark.administrativeArea ?? ""
                        let city = placemark.locality ?? ""
                        let country = placemark.country ?? ""
                        if country != self.setCountry && city != self.setCity {
                            self.setCountry = country
                            self.setState = state
                            self.setCity = city
                            self.start(zipCode: zipCode, country: country)
                        } else {
                            self.service.refresh(country: country, state: state, city: city) { shop in
                                var temp = shop
                                for i in 0..<temp.count {
                                    temp[i].tags = temp[i].tagJoined.split(separator: ",").map { String($0) }
                                }
                                let avoid = self.shopContent[0].display + self.shopContent[0].holder
                                temp.removeAll { element in
                                    return avoid.contains(element)
                                }
                                self.shopContent[0].display.insert(contentsOf: temp, at: 0)
                            }
                        }
                    }
                }
            }
        } else { start(zipCode: zipCode, country: country) }
    }
    func sortNew(){
        if var element = shopContent.first?.display {
            element.sort { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
            shopContent[0].display = element
        }
    }
    func sortPriceAscend(){
        if var element = shopContent.first?.display {
            element.sort { $0.price < $1.price }
            shopContent[0].display = element
        }
    }
    func sortPriceDescend(){
        if var element = shopContent.first?.display {
            element.sort { $0.price > $1.price }
            shopContent[0].display = element
        }
    }
    func sortClose(){
        if let element = shopContent.first?.display {
            var close: [Shop] = []
            var far: [Shop] = []
            for shop in element {
                let components = shop.location.components(separatedBy: ",")
                if components.count == 3 {
                    if components[2] == setCity {
                        close.append(shop)
                    } else {
                        far.append(shop)
                    }
                } else {
                    far.append(shop)
                }
            }
            let final = close + far
            shopContent[0].display = final
        }
    }
    func editPrice(withId: String, location: String, newPrice: Int){
        service.editPrice(withId: withId, location: location, newPrice: newPrice)
    }
    func deletePost(id: String, location: String, images: [String]){
        service.deleteShop(withId: id, location: location, photoUrls: images)
    }
    func isValidZipCode(_ zipCode: String) -> Bool {
        let trimmedZipCode = zipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedZipCode.isEmpty && zipCode != "zipCode"
    }
}

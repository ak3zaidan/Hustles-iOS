import Foundation
import CoreLocation
import FirebaseFirestore
import Firebase
import SwiftUI

struct JobPlaces: Identifiable {
    let id: String
    var Country: String
    var state: String
    var city: String
    var possible_locs: [(String, Timestamp?, Bool)]
    var close: [Tweet]
    var outsideSearchIndex: Int
    var afterException: Bool
}

class JobViewModel: ObservableObject {
    @Published var AssosiatedState = ""
    @Published var AssosiatedCity = ""
    @Published var AssosiatedCountry = ""
    
    @Published var shopContent = [JobPlaces]()
    @Published var jobsThree = [Tweet]()
    @Published var farAway: ([Tweet], String)? = nil
    @Published var zip = "zipCode"
    @Published var menuGetLocationButton: String = "Update in Settings"
    @Published var startedComplete: Bool = false
    @Published var completingJobResult: String = ""
    @Published var saleDelete = [String]()
    let service = JobService()
    let serviceFour = ExploreService()
    let serviceFive = UserService()
    let manager = LocationManager()
    let geocoder = CLGeocoder()
    
    @Published var noResultsFound: Bool = false
    @Published var zipChanged: Bool = false

    var lastRemote: Timestamp = Timestamp(seconds: 2, nanoseconds: 2)
    
    @Published var allUsers = [User]()
    @Published var convoUsers = [User]()
    
    @Published var distance: DropdownMenuOption? = nil
    @Published var countryToSet: String = ""
    
    init(){
        getZipCode { _, _ in }
    }
    
    func start(country: String, ads: [Tweet]){
        if !AssosiatedCountry.isEmpty && !AssosiatedCity.isEmpty {
            if let x = shopContent.firstIndex(where: { $0.Country == AssosiatedCountry && $0.state == AssosiatedState && $0.city == AssosiatedCity }) {
                if x != 0 {
                    let elementToMove = shopContent.remove(at: x)
                    shopContent.insert(elementToMove, at: 0)
                }
                startSecond(byPass: false, ads: ads)
            } else {
                let newElement = JobPlaces(id: "\(UUID())", Country: AssosiatedCountry, state: AssosiatedState, city: AssosiatedCity, possible_locs: [], close: [], outsideSearchIndex: -1, afterException: false)
                shopContent.insert(newElement, at: 0)
                startSecond(byPass: false, ads: ads)
            }
        } else {
            if isValidZipCode(zip) {
                var geoLoc = zip
                if !country.isEmpty { geoLoc = self.zip + " " + country }
                geocoder.geocodeAddressString(geoLoc) { (placemarks, _ ) in
                    if let placemarks = placemarks, let placemark = placemarks.first {
                        self.AssosiatedState = placemark.administrativeArea ?? ""
                        self.AssosiatedCity = placemark.locality ?? ""
                        self.AssosiatedCountry = placemark.country ?? ""
                        self.start(country: self.AssosiatedCountry, ads: ads)
                    } else {
                        self.noResultsFound = true
                        if let first = self.shopContent.first, !first.state.isEmpty {
                            self.getFarAway(country: first.Country, state: first.state)
                        }
                    }
                }
            } else {
                self.noResultsFound = true
            }
        }
    }
    func startSecond(byPass: Bool, ads: [Tweet]) {
        if let element = shopContent.first {
            if element.close.isEmpty && !byPass {
                service.fetch25Jobs(country: AssosiatedCountry, state: AssosiatedState, city: AssosiatedCity, last: nil as Timestamp?) { job in
                    if !job.isEmpty {
                        let toAdd = self.sortArrayWithPromotionPriority(array: job)
                        self.shopContent[0].close = self.insert_ads(ads: ads, jobs: toAdd)
                        let new: (String, Timestamp?, Bool) = (self.AssosiatedCity, job.last?.timestamp, job.count < 24 ? true : false)
                        self.shopContent[0].possible_locs.append(new)
                    } else {
                        let new: (String, Timestamp?, Bool) = (self.AssosiatedCity, nil, true)
                        self.shopContent[0].possible_locs.append(new)
                    }
                    if job.count < 24 || element.possible_locs.isEmpty {
                        self.startSecond(byPass: true, ads: ads)
                    }
                }
            } else if element.possible_locs.count <= 1 {
                for i in 0..<shopContent.count {
                    if ((!AssosiatedState.isEmpty && shopContent[i].Country == AssosiatedCountry && shopContent[i].state == AssosiatedState) || (AssosiatedState.isEmpty && shopContent[i].Country == AssosiatedCountry)) && shopContent[i].city != element.city {
                        var temp = shopContent[i].possible_locs
                        temp.removeAll(where: { $0.0 == AssosiatedCity })
                        shopContent[0].possible_locs.append(contentsOf: temp)

                        var all_Possible = shopContent[i].close
                        all_Possible.removeAll { element in
                            return shopContent[0].close.contains(element)
                        }
                        var close = [Tweet]()
                        var far = [Tweet]()
                        all_Possible.forEach { jobTemp in
                            if jobTemp.start == nil {
                                if let loc = jobTemp.appIdentifier, loc.contains(AssosiatedCity) {
                                    close.append(jobTemp)
                                } else {
                                    far.append(jobTemp)
                                }
                            }
                        }
                        if (close.count + self.shopContent[0].close.count) == 1 && !far.isEmpty {
                            self.shopContent[0].afterException = true
                        }
                        if self.shopContent[0].close.isEmpty && close.isEmpty && !far.isEmpty {
                            self.shopContent[0].outsideSearchIndex = 0
                        } else if (!self.shopContent[0].close.isEmpty || !close.isEmpty) && !far.isEmpty {
                            self.shopContent[0].outsideSearchIndex = (close.count + self.shopContent[0].close.count) - 1
                        }
                        self.shopContent[0].close.insert(contentsOf: close, at: 0)
                        self.shopContent[0].close.append(contentsOf: far)
                        
                        if shopContent[0].close.count < 20 {
                            self.getClose(ads: ads)
                        }
                        return
                    }
                }
                service.getPossibleLocations(country: AssosiatedCountry, withState: AssosiatedState) { locations in
                    if !locations.isEmpty {
                        locations.forEach { loc in
                            if !element.possible_locs.contains(where: { $0.0 == loc.place }){
                                let newPlace: (String, Timestamp?, Bool) = (loc.place, nil, false)
                                self.shopContent[0].possible_locs.append(newPlace)
                            }
                        }
                        if element.close.count < 20 {
                            self.getClose(ads: ads)
                        }
                    } else if element.close.isEmpty {
                        self.noResultsFound = true
                        if !self.shopContent[0].state.isEmpty {
                            self.getFarAway(country: self.shopContent[0].Country, state: self.shopContent[0].state)
                        }
                    }
                }
            }
        }
    }
    func getClose(ads: [Tweet]){
        if let element = shopContent.first {
            var x = 0
            for i in 0..<element.possible_locs.count {
                if !element.possible_locs[i].2 {
                    x = i
                    break
                }
            }
            if x > 0 || (x == 0 && !element.possible_locs[0].2) {
                service.fetch25Jobs(country: AssosiatedCountry, state: AssosiatedState, city: element.possible_locs[x].0, last: element.possible_locs[x].1) { job in
                    var temp = job
                    temp.removeAll(where: { self.shopContent[0].close.contains($0) })
                    temp = self.sortArrayWithPromotionPriority(array: temp)
                    
                    if element.city != element.possible_locs[x].0 {
                        var close = [Tweet]()
                        var far = [Tweet]()
                        far.append(contentsOf: temp)
                        
                        let original_city = element.city
                        element.close.forEach { job in
                            if job.start == nil {
                                if let place = job.appIdentifier, place.contains(original_city) {
                                    close.append(job)
                                } else {
                                    far.append(job)
                                }
                            }
                        }
                        if close.count == 1 && !far.isEmpty {
                            self.shopContent[0].afterException = true
                        }
                        if close.isEmpty && !far.isEmpty {
                            self.shopContent[0].outsideSearchIndex = 0
                        } else if !close.isEmpty && !far.isEmpty {
                            self.shopContent[0].outsideSearchIndex = close.count - 1
                        }
                    }
                    
                    self.shopContent[0].close += temp
                    if temp.count < 24 {
                        self.shopContent[0].possible_locs[x].2 = true
                        self.getClose(ads: ads)
                    } else {
                        self.shopContent[0].close = self.insert_ads(ads: ads, jobs: self.shopContent[0].close)
                        self.shopContent[0].possible_locs[x].1 = job.last?.timestamp
                    }
                }
            } else if shopContent[0].close.isEmpty {
                noResultsFound = true
                if !shopContent[0].state.isEmpty {
                    getFarAway(country: shopContent[0].Country, state: shopContent[0].state)
                }
            }
        }
    }
    func getFarAway(country: String, state: String) {
        if farAway == nil {
            service.getFarAway(country: country, avoid: state) { jobs, place in
                if !jobs.isEmpty {
                    self.farAway = (jobs, "Results from \(place) \(country).")
                }
            }
        }
    }
    func refreshClose() {
        if let element = shopContent.first {
            service.new25Jobs(country: element.Country, state: element.state, city: element.city) { job in
                var temp = job
                temp.removeAll(where: { self.shopContent[0].close.contains($0) })
                if !temp.isEmpty {
                    self.shopContent[0].close.insert(contentsOf: temp, at: 0)
                    if element.outsideSearchIndex >= 0 {
                        self.shopContent[0].outsideSearchIndex += temp.count
                    }
                }
            }
        }
    }
    func insert_ads(ads: [Tweet], jobs: [Tweet]) -> [Tweet] {
        var job = jobs
        if job.count > 10 && !ads.isEmpty {
            job.removeAll(where: { $0.start != nil })
            for i in stride(from: 0, to: job.count, by: 14) {
                if var first = ads.randomElement() {
                    let ran1 = String(UUID().uuidString.prefix(4))
                    first.id = (first.id ?? "") + ran1
                    job.insert(first, at: i)
                }
            }
            return job
        } else {
            return job
        }
    }
    func getRemoteJobs(completion: @escaping([Tweet]) -> Void){
        service.fetchRemoteJobs { jobs in
            self.jobsThree = jobs
            self.lastRemote = jobs.last?.timestamp ?? Timestamp(seconds: 2, nanoseconds: 2)
            self.jobsThree = self.sortArrayWithPromotionPriority(array: self.jobsThree)
            completion(self.jobsThree)
        }
    }
    func beginRemote(ads: [Tweet]){
        getRemoteJobs() { jobs in
            var x = jobs
            if x.count > 10 {
                if !ads.isEmpty {
                    if var first = ads.randomElement(), var second = ads.randomElement() {
                        let ran1 = String(UUID().uuidString.prefix(4))
                        let ran2 = String(UUID().uuidString.prefix(4))
                        first.id = (first.id ?? "") + ran1
                        second.id = (second.id ?? "") + ran2
                        let half = Int(round(Double(x.count) / 2.0))
                        if first.plus == nil && second.plus != nil {
                            x.insert(second, at: half)
                            x.append(first)
                            self.jobsThree = x
                        } else {
                            x.insert(first, at: half)
                            x.append(second)
                            self.jobsThree = x
                        }
                    }
                }
            }
        }
    }
    func getRemoteMoreJobs(lastdoc: Timestamp, completion: @escaping([Tweet]) -> Void){
        service.fetchRemoteJobsAfter(lastdoc: lastdoc) { jobs in
            var x = jobs
            self.lastRemote = jobs.last?.timestamp ?? Timestamp(seconds: 2, nanoseconds: 2)
            x = self.sortArrayWithPromotionPriority(array: x)
            completion(x)
        }
    }
    func beginAddMoreRemote(lastdoc: Timestamp, ads: [Tweet]){
        getRemoteMoreJobs(lastdoc: lastdoc) { jobs in
            var x = jobs
            if x.count > 10 {
                if !ads.isEmpty {
                    if var first = ads.randomElement(), var second = ads.randomElement() {
                        let ran1 = String(UUID().uuidString.prefix(4))
                        let ran2 = String(UUID().uuidString.prefix(4))
                        first.id = (first.id ?? "") + ran1
                        second.id = (second.id ?? "") + ran2
                        let half = Int(round(Double(x.count) / 2.0))
                        if first.plus == nil && second.plus != nil {
                            x.insert(second, at: half)
                            x.append(first)
                            self.jobsThree += x
                        } else {
                            x.insert(first, at: half)
                            x.append(second)
                            self.jobsThree += x
                        }
                    } else {
                        self.jobsThree += x
                    }
                } else { self.jobsThree += x }
            } else { self.jobsThree += x }
        }
    }
    func getZipCode(completion: @escaping(String, String) -> Void){
        manager.requestLocation() { place in
            if let zip = place.0, let country = place.1 {
                self.zip = zip
                self.menuGetLocationButton = "Current Location"
                self.countryToSet = country
                completion(zip, country)
            } else if let zip = place.0 {
                self.zip = zip
                self.menuGetLocationButton = "Current Location"
                completion(zip, "")
            } else {
                completion("", "")
            }
        }
    }
    func uploadZipToDatabase(withZip zipCode: String){
        service.uploadZipToDatabase(forZip: zipCode)
    }
    func isValidZipCode(_ zipCode: String) -> Bool {
        let trimmedZipCode = zipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedZipCode.isEmpty && zipCode != "zipCode"
    }
    func startCompleteJob(chats: [Chats], following: [String], userpointer: [String]){
        if chats.isEmpty && convoUsers.isEmpty {
            MessageService().getConversations(pointers: userpointer) { elements in
                elements.forEach { element in
                    if !self.convoUsers.contains(where: { $0.username == element.1.username }) {
                        self.convoUsers.append(element.1)
                    }
                }
                if (self.allUsers.count + self.convoUsers.count) < 12 {
                    let randomFollowing = Array(following.shuffled().prefix(16))
                    self.serviceFive.getManyUsers(users: randomFollowing, limit: 16) { all in
                        self.allUsers = all
                    }
                }
            }
        } else {
            chats.forEach { chat in
                if !self.convoUsers.contains(where: { $0.username == chat.user.username }) {
                    self.convoUsers.append(chat.user)
                }
            }
            if (self.allUsers.count + self.convoUsers.count) < 12 {
                let randomFollowing = Array(following.shuffled().prefix(16))
                serviceFive.getManyUsers(users: randomFollowing, limit: 16) { all in
                    self.allUsers = all
                }
            }
        }
    }
    func getFollowing(following: [String], count: Int){
        let randomFollowing = Array(following.shuffled().prefix(count))
        self.serviceFive.getManyUsers(users: randomFollowing, limit: count) { all in
            self.allUsers = all
        }
    }
    func searchCompleteJob(string: String, uid: String){
        serviceFour.searchUsers(name: string) { users in
            self.serviceFour.searchFullname(name: string) { usersSec in
                var all = Array(Set(users + usersSec))

                all = all.filter { user in
                    return user.id != uid && !self.allUsers.contains(user) && user.dev == nil
                }

                self.allUsers.insert(contentsOf: all, at: 0)
            }
        }
    }
    func sortUsers(string: String) {
        let lowercasedQuery = string.lowercased()
        allUsers.sort { (user1, user2) -> Bool in
            let lowercasedUser1 = user1.username.lowercased()
            let lowercasedUser2 = user2.username.lowercased()
            
            if lowercasedUser1.contains(lowercasedQuery) && !lowercasedUser2.contains(lowercasedQuery) {
                return true
            } else if !lowercasedUser1.contains(lowercasedQuery) && lowercasedUser2.contains(lowercasedQuery) {
                return false
            } else {
                return lowercasedUser1 < lowercasedUser2
            }
        }
    }
    func finishJob(user: User, job: Tweet){
        startedComplete = true
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "MMMM dd, yyyy 'at' h:mm a"
        if let dayBetween = Calendar.current.dateComponents([.day], from: user.timestamp.dateValue(), to: Date()).day{
            if (Double(user.completedjobs) / Double(dayBetween)) > 0.3 {
                startedComplete = false
                self.completingJobResult = "This user has done too many jobs in a short period... Contact us if this is an error."
                return
            }
        }
        service.CheckJobExists(withId: job.id ?? "", location: job.appIdentifier) { success in
            if success {
                var amount = 0
                if user.elo < 600 { amount = 200
                } else if user.elo < 850 { amount = 150
                } else if user.elo < 1300 { amount = 100
                } else if user.elo < 2000 { amount = 50
                } else if user.elo < 2900 { amount = 25
                } else { amount = 12 }
                self.serviceFive.editElo(withUid: user.id, withAmount: amount) {}
                self.service.IncCompletedJobs(withUid: user.id)
                self.service.deleteJob(withId: job.id ?? "", location: job.appIdentifier ?? nil)
                self.startedComplete = false
            } else {
                self.startedComplete = false
                self.completingJobResult = "Error finding job"
            }
        }
    }
    func finishSale(user: User, sale: Shop){
        if let id = sale.id, !id.isEmpty && !self.saleDelete.contains(id) {
            self.service.IncBought(userid: user.id)
            self.service.IncSold()
            self.saleDelete.append(id)
            ShopService().deleteShop(withId: id, location: sale.location, photoUrls: sale.photos)
        }
    }
    func deleteJob(job: Tweet){
        service.deleteJob(withId: job.id ?? "", location: job.appIdentifier ?? nil)
        if let imageURL = job.image {
            ImageUploader.deleteImage(fileLocation: imageURL) { _ in }
        }
    }
    func sortArrayWithPromotionPriority(array: [Tweet]) -> [Tweet] {
        let currentDate = Date()
        var promotedArray: [Tweet] = []
        var nonPromotedArray: [Tweet] = []
        for tweet in array {
            if tweet.promoted?.dateValue() ?? currentDate > currentDate {
                promotedArray.append(tweet)
            } else {
                nonPromotedArray.append(tweet)
            }
        }
        return promotedArray + nonPromotedArray
    }
    func updateCountry(country: String){ service.updateUserCountry(country: country) }
}

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestoreSwift
import SceneKit

struct Story: Decodable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var uid: String
    var username: String
    var profilephoto: String?
    var long: Double?
    var lat: Double?
    var text: String?
    var textPos: Double?
    var imageURL: String?
    var videoURL: String?
    var timestamp: Timestamp
    var link: String?
    var geoHash: String?
    var views: [String]?
    var muted: Bool?
    var infinite: Bool?
}

struct StoryHolder: Identifiable, Equatable {
    var id: String
    var hash: String
    var content: [Story]
}

struct myLoc {
    var country: String
    var state: String
    var city: String
    var lat: Double
    var long: Double
}

class GlobeViewModel: ObservableObject {    
    @Published var allStories = [StoryHolder]()
    @Published var currentStory = [Story]()
    @Published var friends = [Story]()
    @Published var gettingFriends: Bool = false
    @Published var option: Int = 2
    @Published var hideSearch: Bool = false
    @Published var showStoryLoader: Bool = false
    @Published var currentLocation: myLoc? = nil
    @EnvironmentObject var profile: ProfileViewModel
    let service = GlobeService()
    
    @Published var couldntFindContent: Bool = false
    @Published var showMainStories: Bool = false
    @Published var focusLocation: FocusLocation?
    @Published var searching: Bool = false
    
    init(){
        GlobeLocationManager().requestLocation { place in
            if !place.0.isEmpty && !place.1.isEmpty {
                self.currentLocation = myLoc(country: place.1, state: place.4, city: place.0, lat: place.2, long: place.3)
            }
        }
    }

    func handleGlobeTap(place: String, neighbors: [String]){
        self.searching = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0){
            self.searching = false
        }
        if place.isEmpty && neighbors.isEmpty {
            couldntFindContent.toggle()
            return
        }
        if !place.isEmpty {
            if let storys = allStories.first(where: { $0.hash == place })?.content {
                if storys.isEmpty {
                    if let first = neighbors.first {
                       var temp = neighbors
                       temp.removeFirst()
                       handleGlobeTap(place: first, neighbors: temp)
                    } else {
                        couldntFindContent.toggle()
                        return
                    }
                } else {
                    currentStory = storys
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                        self.showMainStories.toggle()
                    }
                }
            } else {
                service.getStoryRegion(hash: place, limit: 50) { stories in
                    if let x = self.allStories.firstIndex(where: { $0.hash == place }) {
                        if !stories.isEmpty {
                            self.allStories[x].content = Array(Set(self.allStories[x].content + stories))
                        }
                    } else {
                        self.allStories.append(StoryHolder(id: "\(UUID())", hash: place, content: stories))
                    }
                    
                    if stories.isEmpty && neighbors.isEmpty {
                        self.couldntFindContent.toggle()
                        return
                    }
                    if !stories.isEmpty {
                        var temp = [Story]()
                        stories.forEach { single in
                            if !self.currentStory.contains(where: { $0.id == single.id }) {
                                temp.append(single)
                            }
                        }
                        self.currentStory = temp
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                            self.showMainStories.toggle()
                        }
                        if stories.count < 8 {
                            self.globeTapHelper(toAppend: place, neighbors: neighbors)
                        }
                    } else if let first = neighbors.first {
                        var temp = neighbors
                        temp.removeFirst()
                        self.handleGlobeTap(place: first, neighbors: temp)
                    }
                }
            }
        } else if let first = neighbors.first {
            var temp = neighbors
            temp.removeFirst()
            handleGlobeTap(place: first, neighbors: temp)
        }
    }
    
    func getMapRegionStories(place: String, neighbors: [String], completion: @escaping ([Story]) -> Void){
        if place.isEmpty && neighbors.isEmpty {
            completion([])
            return
        }
        if !place.isEmpty {
            if let storys = allStories.first(where: { $0.hash == place })?.content {
                if storys.isEmpty {
                    if let first = neighbors.first {
                        var temp = neighbors
                        temp.removeFirst()
                        getMapRegionStories(place: first, neighbors: temp) { stories in
                            completion(stories)
                        }
                    } else {
                        completion([])
                    }
                } else {
                    completion(storys)
                }
            } else {
                service.getStoryRegion(hash: place, limit: 25) { stories in
                    if let x = self.allStories.firstIndex(where: { $0.hash == place }) {
                        if !stories.isEmpty {
                            self.allStories[x].content = Array(Set(self.allStories[x].content + stories))
                        }
                    } else {
                        self.allStories.append(StoryHolder(id: "\(UUID())", hash: place, content: stories))
                    }
                    
                    if stories.isEmpty && neighbors.isEmpty {
                        completion([])
                        return
                    }
                    if !stories.isEmpty {
                        completion(stories)
                    } else if let first = neighbors.first {
                        var temp = neighbors
                        temp.removeFirst()
                        self.getMapRegionStories(place: first, neighbors: temp) { stories in
                            completion(stories)
                        }
                    }
                }
            }
        } else if let first = neighbors.first {
            var temp = neighbors
            temp.removeFirst()
            getMapRegionStories(place: first, neighbors: temp) { stories in
                completion(stories)
            }
        }
    }
    
    func globeTapHelper(toAppend: String, neighbors: [String]){
        neighbors.forEach { element in
            service.getStoryRegion(hash: element, limit: 7) { stories in
                var temp = [Story]()
                stories.forEach { single in
                    if !self.currentStory.contains(where: { $0.id == single.id }) {
                        temp.append(single)
                    }
                }
                if let x = self.allStories.firstIndex(where: { $0.hash == toAppend }) {
                    self.allStories[x].content.append(contentsOf: temp)
                }
                if self.currentStory.first?.geoHash == toAppend {
                    self.currentStory.append(contentsOf: temp)
                }
            }
        }
    }
    func uploadStoryImage(caption: String, captionPos: Double, link: String?, image: UIImage, id: String, uid: String, username: String, userphoto: String?, infinite: Bool?, optionalLoc: myLoc?){
        if let loc = optionalLoc ?? currentLocation, !uid.isEmpty {
            ImageUploader.uploadImage(image: image, location: "stories", compression: 0.25) { urlLoc, _ in
                
                let captionF = caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : caption
                
                self.service.uploadStory(caption: captionF, captionPos: captionPos, link: link, imageLink: urlLoc, videoLink: nil, id: id, uid: uid, username: username, userphoto: userphoto, long: loc.long, lat: loc.lat, muted: false, infinite: infinite)
            }
        }
    }
    func uploadStoryVideo(caption: String, captionPos: Double, link: String?, videoURL: URL, id: String, uid: String, username: String, userphoto: String?, muted: Bool, infinite: Bool?, optionalLoc: myLoc?){
        if let loc = optionalLoc ?? currentLocation, !uid.isEmpty {
            ImageUploader.uploadVideoToFirebaseStorage(localVideoURL: videoURL) { urlLoc in
                if let final_url = urlLoc {
                    let captionF = caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : caption
                    
                    self.service.uploadStory(caption: captionF, captionPos: captionPos, link: link, imageLink: nil, videoLink: final_url, id: id, uid: uid, username: username, userphoto: userphoto, long: loc.long, lat: loc.lat, muted: muted, infinite: infinite)
                }
            }
        }
    }
    func getFriendStories(friends: [String], completion: @escaping(Bool) -> Void){
        if self.friends.isEmpty {
            if !gettingFriends {
                gettingFriends = true
                let final = Array(Set(friends))
                if final.isEmpty {
                    completion(false)
                    return
                }
                service.getFriends(all: final) { story in
                    self.gettingFriends = false
                    story.forEach { single in
                        if !self.friends.contains(single) {
                            self.friends.append(single)
                        }
                    }
                    completion(!self.friends.isEmpty)
                }
            }
        } else {
            completion(true)
        }
    }
}

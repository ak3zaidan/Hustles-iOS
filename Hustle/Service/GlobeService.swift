import Firebase
import Foundation
import CoreLocation
import SwiftBridging

struct GlobeService {
    let db = Firestore.firestore()
    
    func uploadStory(caption: String?, captionPos: Double, link: String?, imageLink: String?, videoLink: String?, id: String, uid: String, username: String, userphoto: String?, long: Double?, lat: Double?, muted: Bool, infinite: Bool?){
        var data = ["uid": uid,
                    "username": username,
                    "timestamp": Timestamp(date: Date())] as [String : Any]
        
        if let userP = userphoto {
            data["profilephoto"] = userP
        }
        if let text = caption, !text.isEmpty {
            data["text"] = text
            data["textPos"] = captionPos
        }
        if let urlLink = link {
            data["link"] = urlLink
        }
        if let contentLink = imageLink {
            data["imageURL"] = contentLink
        }
        if let contentLink = videoLink {
            data["videoURL"] = contentLink
            data["muted"] = muted
        }
        if infinite != nil {
            data["infinite"] = true
        }
        if let lat = lat, let long = long {
            data["lat"] = lat
            data["long"] = long
            
            let point = CLLocationCoordinate2D(latitude: lat, longitude: long)
            let index = point.h3CellIndex(resolution: 1)

            let hash = String(index, radix: 16, uppercase: true)

            data["geoHash"] = hash
        }

        db.collection("stories").document(id).setData(data) { _ in }
    }
    func deleteStory(storyID: String?){
        if let id = storyID, !id.isEmpty {
            db.collection("stories").document(id).delete()
        }
    }
    func addStoryView(storyID: String?, emoji: String){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        if let id = storyID, !id.isEmpty {
            var final = uid
            if !emoji.isEmpty {
                final += "/\(emoji)"
            }
            db.collection("stories").document(id)
                .updateData([ "views": FieldValue.arrayUnion([final]) ]) { _ in }
        }
    }
    func removeStoryView(storyID: String?, viewName: String){
        if let id = storyID, !id.isEmpty && !viewName.isEmpty {
            db.collection("stories").document(id)
                .updateData([ "views": FieldValue.arrayRemove([viewName]) ]) { _ in }
        }
    }
    func getUserStories(otherUser: String?, completion: @escaping([Story]) -> Void){
        var id = ""
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        if let other_user = otherUser {
            id = other_user
        } else {
            id = uid
        }
        
        db.collection("stories")
            .whereField("uid", isEqualTo: id).limit(to: 80)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let stories = documents.compactMap({ try? $0.data(as: Story.self)} )
                completion(extractOld(original: stories, order: false))
            }
    }
    func getFriends(all: [String], completion: @escaping([Story]) -> Void){
        if !all.isEmpty {
            db.collection("stories")
                .whereField("uid", in: all).limit(to: 80)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    let stories = documents.compactMap({ try? $0.data(as: Story.self)} )
                    completion(extractOld(original: stories, order: true))
                }
        } else {
            completion([])
        }
    }
    func getStoryRegion(hash: String, limit: Int, completion: @escaping([Story]) -> Void){
        if !hash.isEmpty {
            db.collection("stories")
                .whereField("geoHash", isEqualTo: hash).limit(to: limit)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    let stories = documents.compactMap({ try? $0.data(as: Story.self)} )
                    completion(extractOld(original: stories, order: true))
                }
        } else {
            completion([])
        }
    }
    func getSingleStory(id: String, completion: @escaping(Story?) -> Void){
        if !id.isEmpty {
            db.collection("stories").document(id)
                .getDocument { snapshot, _ in
                    guard let snapshot = snapshot else {
                        completion(nil)
                        return
                    }
                    let story = try? snapshot.data(as: Story.self)
                    completion(story)
                }
        } else {
            completion(nil)
        }
    }
    func getStoryViews(id: String, completion: @escaping(User?) -> Void){
        if !id.isEmpty {
            db.collection("users")
                .whereField("uid", isGreaterThanOrEqualTo: id)
                .whereField("uid", isLessThanOrEqualTo: id + "\u{f8ff}")
                .limit(to: 1)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        completion(nil)
                        return
                    }
                    let user = documents.compactMap({ try? $0.data(as: User.self)} ).first
                    completion(user)
                }
        } else {
            completion(nil)
        }
    }
    func extractOld(original: [Story], order: Bool) -> [Story] {
        var final: [Story] = []
        let twentyFourHoursInSeconds: TimeInterval = 48 * 60 * 60
        let currentTime = Date()
        
        original.forEach { element in
            if element.infinite == nil {
                let storyTimestamp = element.timestamp.dateValue()
                let timeDifference = currentTime.timeIntervalSince(storyTimestamp)
                
                if timeDifference <= twentyFourHoursInSeconds {
                    // Story is within the last 48 hours
                    final.append(element)
                } else if let id = element.id, !id.isEmpty {
                    // Story is older than 48 hours
                    db.collection("stories").document(id).delete()
                }
            } else {
                final.append(element)
            }
        }
        
        if order {
            return orderStories(original: final)
        } else {
            return final.sorted(by: { $0.timestamp.dateValue() < $1.timestamp.dateValue() })
        }
    }
    func orderStories(original: [Story]) -> [Story] {
        var groupedStories: [String: [Story]] = [:]

        original.forEach { story in
            if var storiesForUid = groupedStories[story.uid] {
                storiesForUid.append(story)
                groupedStories[story.uid] = storiesForUid
            } else {
                groupedStories[story.uid] = [story]
            }
        }
        for uid in groupedStories.keys {
            if var storiesForUid = groupedStories[uid] {
                storiesForUid.sort { $0.timestamp.dateValue() < $1.timestamp.dateValue() }
                groupedStories[uid] = storiesForUid
            }
        }
        
        var final = [Story]()
        groupedStories.forEach { (key: String, value: [Story]) in
            final.append(contentsOf: value)
        }

        return final
    }
}

extension CLLocationCoordinate2D {
    public func h3CellIndex(resolution: Int32) -> UInt64 {
        let lat = degsToRads(latitude)
        let lon = degsToRads(longitude)
        var location = GeoCoord(lat: lat, lon: lon)
        let index = geoToH3(&location, resolution)
        return index
    }
    public func h3Neighbors( resolution: Int32, ringLevel: Int32 ) -> [H3Index] {
        let index = h3CellIndex(resolution: resolution)
        let count = Int(maxKringSize(ringLevel))
        var neighbors = Array(repeating: H3Index(), count: count)
        kRing(index, ringLevel, &neighbors);
        return neighbors
    }
}

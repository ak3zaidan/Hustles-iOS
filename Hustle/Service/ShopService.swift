import Firebase
import UIKit
import SwiftUI

struct ShopService {
    let db = Firestore.firestore()
    
    func uploadShop(title: String, caption: String, price: String, tags: [String], images: [UIImage], promoted: Int, city: String, state: String, country: String, username: String, profilePhoto: String?, completion: @escaping(Bool) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let tagString = tags.joined(separator: ",")
        var data = ["uid": uid,
                    "caption": caption,
                    "title": title,
                    "location": country + "," + state + "," + city,
                    "username": username,
                    "tagJoined": tagString,
                    "price": Int(price) ?? 49,
                    "timestamp": Timestamp(date: Date())] as [String : Any]
        
        if promoted > 0 {
            let date = Calendar.current.date(byAdding: .day, value: promoted + 1, to: Date())!
            data["promoted"] = Timestamp(date: date)
        }
        if let userPhoto = profilePhoto {
            data["profilephoto"] = userPhoto
        }

        let placeHolder = ["place": city]
        var query = db.collection("shop").document(country).collection("shop").document(city)
        if !state.isEmpty {
            query = db.collection("shop").document(country).collection("shop").document(state).collection("shop").document(city)
        }
            
        ImageUploader.uploadMultipleImages(images: images, location: "shop", compression: 0.25) { strArr in
            data["photos"] = strArr
            query.setData(placeHolder) { _ in  }
            query.collection("shop").document()
                .setData(data) { error in
                    if error != nil {
                        completion(false)
                        return
                    }
                    completion(true)
                }
            
        }
    }
    func deleteShop(withId: String, location: String, photoUrls: [String]){
        photoUrls.forEach { url in
            ImageUploader.deleteImage(fileLocation: url) { _ in }
        }
        if !withId.isEmpty {
            let substrings = location.split(separator: ",")
            if substrings.count == 3 {
                let country = String(substrings[0])
                let state = String(substrings[1])
                let city = String(substrings[2])
                
                if state.isEmpty {
                    db.collection("shop").document(country).collection("shop").document(city).collection("shop").document(withId).delete()
                } else {
                    db.collection("shop").document(country).collection("shop").document(state).collection("shop").document(city).collection("shop").document(withId).delete()
                }
            }
        }
    }
    func addShopPointer(location: String){
        if !location.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let docRef = db.collection("users").document(uid)
            docRef.updateData([ "shopPointer": FieldValue.arrayUnion([location]) ]) { _ in }
        }
    }
    func editPrice(withId: String, location: String, newPrice: Int){
        if !withId.isEmpty {
            let substrings = location.split(separator: ",")
            if substrings.count == 3 {
                let country = String(substrings[0])
                let state = String(substrings[1])
                let city = String(substrings[2])
                
                if state.isEmpty {
                    db.collection("shop").document(country).collection("shop").document(city).collection("shop").document(withId).updateData([ "price": newPrice]) { _ in }
                } else {
                    db.collection("shop").document(country).collection("shop").document(state).collection("shop").document(city).collection("shop").document(withId).updateData([ "price": newPrice ]) { _ in }
                }
            }
        }
    }
    func fetchClose(country: String, state: String, city: String, last: Timestamp?, completion: @escaping([Shop]) -> Void){
        if !country.isEmpty && !city.isEmpty {
            var query = db.collection("shop").document(country).collection("shop").document(city).collection("shop").order(by: "timestamp", descending: true).limit(to: 30)
            
            if let last = last {
                query = db.collection("shop").document(country).collection("shop").document(city).collection("shop").whereField("timestamp", isLessThan: last).order(by: "timestamp", descending: true).limit(to: 30)
            }
            
            if !state.isEmpty {
                query = db.collection("shop").document(country).collection("shop").document(state).collection("shop").document(city).collection("shop").order(by: "timestamp", descending: true).limit(to: 30)
                
                if let last = last {
                    query = db.collection("shop").document(country).collection("shop").document(state).collection("shop").document(city).collection("shop").whereField("timestamp", isLessThan: last).order(by: "timestamp", descending: true).limit(to: 30)
                }
            }
            
            query.getDocuments { snapshot, _ in
                if let documents = snapshot?.documents {
                    let shop = documents.compactMap({ try? $0.data(as: Shop.self)} )
                    completion(shop)
                } else {
                    completion([])
                }
            }
        } else {
            completion([])
        }
    }
    func getTag(country: String, state: String, city: String, tag: String, completion: @escaping([Shop]) -> Void){
        if !country.isEmpty && !city.isEmpty {
            var query = db.collection("shop").document(country).collection("shop").document(city).collection("shop")
            
            if !state.isEmpty {
                query = db.collection("shop").document(country).collection("shop").document(state).collection("shop").document(city).collection("shop")
            }
            
            query.whereField("tagJoined", isGreaterThanOrEqualTo: tag)
                .whereField("tagJoined", isLessThanOrEqualTo: tag + "\u{f8ff}").limit(to: 75)
                .getDocuments { snapshot, _ in
                    if let documents = snapshot?.documents {
                        let shop = documents.compactMap({ try? $0.data(as: Shop.self)} )
                        completion(shop)
                    } else {
                        completion([])
                    }
                }
        } else {
            completion([])
        }
    }
    func getPossibleLocations(country: String, state: String, completion: @escaping([Location]) -> Void){
        if !country.isEmpty {
            var query = db.collection("shop").document(country).collection("shop").order(by: "place").limit(to: 20)
            if !state.isEmpty {
                query = db.collection("shop").document(country).collection("shop").document(state).collection("shop").order(by: "place").limit(to: 20)
            }
            query.getDocuments { snapshot, error in
                if let documents = snapshot?.documents{
                    let states = documents.compactMap({ try? $0.data(as: Location.self)} )
                    completion(states)
                } else {
                    completion([])
                }
            }
        } else {
            completion([])
        }
    }
    func refresh(country: String, state: String, city: String, completion: @escaping([Shop]) -> Void){
        let currentTimestamp = Timestamp()
        let oneHourInSeconds: TimeInterval = -3600
        let oneHourAgoTimestamp = currentTimestamp.dateValue().addingTimeInterval(oneHourInSeconds)
        let firestoreTimestamp = Timestamp(date: oneHourAgoTimestamp)
        
        fetchNew(country: country, state: state, city: city, last: firestoreTimestamp) { shop in
            completion(shop)
        }
    }
    func fetchNew(country: String, state: String, city: String, last: Timestamp, completion: @escaping([Shop]) -> Void){
        if !country.isEmpty && !city.isEmpty {
            var query = db.collection("shop").document(country).collection("shop").document(city).collection("shop").whereField("timestamp", isGreaterThan: last).order(by: "timestamp", descending: true).limit(to: 30)
            if !state.isEmpty {
                query = db.collection("shop").document(country).collection("shop").document(state).collection("shop").document(city).collection("shop").whereField("timestamp", isGreaterThan: last).order(by: "timestamp", descending: true).limit(to: 30)
            }
            
            query.getDocuments { snapshot, _ in
                if let documents = snapshot?.documents {
                    let shop = documents.compactMap({ try? $0.data(as: Shop.self)} )
                    completion(shop)
                } else {
                    completion([])
                }
            }
        } else { completion([]) }
    }
}

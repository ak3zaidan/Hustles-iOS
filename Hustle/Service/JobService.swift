import Firebase
import UIKit

struct JobService {
    let db = Firestore.firestore()

    func uploadJobImage(caption: String, title: String, city: String, state: String, remote: Bool, image: UIImage?, promoted: Int, link: String, photo: String, username: String, country: String, completion: @escaping(Bool) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var data = ["uid": uid,
                    "caption": caption,
                    "tag": title,
                    "username": username,
                    "timestamp": Timestamp(date: Date())] as [String : Any]
        if promoted > 0 {
            let date = Calendar.current.date(byAdding: .day, value: promoted + 1, to: Date())!
            data["promoted"] = Timestamp(date: date)
        }
        if link != "" {
            data["web"] = link
        }
        if !photo.isEmpty{
            data["profilephoto"] = photo
        }
        if !remote {
            data["appIdentifier"] = country + "," + state + "," + city
        }
        if remote {
            if let image = image{
                ImageUploader.uploadImage(image: image, location: "jobs", compression: 0.25) { jobImageUrl, _ in
                    data["image"] = jobImageUrl
                    db.collection("remote").document()
                        .setData(data) { error in
                            if error != nil {
                                completion(false)
                                return
                            }
                            completion(true)
                        }
                }
            } else {
                db.collection("remote").document()
                    .setData(data) { error in
                        if error != nil {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
            }
        } else {
            let placeHolder = ["place": city]
            
            var query = db.collection("jobs").document(country).collection("jobs").document(city)
            
            if !state.isEmpty {
                query = db.collection("jobs").document(country).collection("jobs").document(state).collection("jobs").document(city)
            }
            
            if let image = image {
                ImageUploader.uploadImage(image: image, location: "jobs", compression: 0.25) { jobImageUrl, _ in
                    data["image"] = jobImageUrl
                    query.setData(placeHolder) { _ in }
                    query.collection("jobs").document()
                        .setData(data) { error in
                            if error != nil {
                                completion(false)
                                return
                            }
                            completion(true)
                        }
                }
            } else {
                query.setData(placeHolder) { _ in }
                query.collection("jobs").document()
                    .setData(data) { error in
                        if error != nil {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
            }
        }
    }
    func addJobPointer(location: String) {
        if !location.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let docRef = db.collection("users").document(uid)
            docRef.updateData([ "jobPointer": FieldValue.arrayUnion([location]) ]) { _ in }
        }
    }
    func fetch25Jobs(country: String, state: String, city: String, last: Timestamp?, completion: @escaping([Tweet]) -> Void){
        if !country.isEmpty && !city.isEmpty {
            var query = db.collection("jobs").document(country).collection("jobs").document(city).collection("jobs").order(by: "timestamp", descending: true).limit(to: 25)
            
            if let last = last {
                query = db.collection("jobs").document(country).collection("jobs").document(city).collection("jobs").whereField("timestamp", isLessThan: last).order(by: "timestamp", descending: true).limit(to: 25)
            }
            
            if !state.isEmpty {
                query = db.collection("jobs").document(country).collection("jobs").document(state).collection("jobs").document(city).collection("jobs").order(by: "timestamp", descending: true).limit(to: 25)
                
                if let last = last {
                    query = db.collection("jobs").document(country).collection("jobs").document(state).collection("jobs").document(city).collection("jobs").whereField("timestamp", isLessThan: last).order(by: "timestamp", descending: true).limit(to: 25)
                }
            }
            
            query.getDocuments { snapshot, error in
                if let documents = snapshot?.documents{
                    let jobs = documents.compactMap({ try? $0.data(as: Tweet.self)} )
                    completion(jobs)
                } else {
                    completion([])
                }
            }
        } else {
            completion([])
        }
    }
    func new25Jobs(country: String, state: String, city: String, completion: @escaping([Tweet]) -> Void){
        if !country.isEmpty && !city.isEmpty {
            var query = db.collection("jobs").document(country).collection("jobs").document(city).collection("jobs").order(by: "timestamp", descending: true).limit(to: 8)
            
            if !state.isEmpty {
                query = db.collection("jobs").document(country).collection("jobs").document(state).collection("jobs").document(city).collection("jobs").order(by: "timestamp", descending: true).limit(to: 8)
            }
            
            query.getDocuments { snapshot, error in
                if let documents = snapshot?.documents{
                    let jobs = documents.compactMap({ try? $0.data(as: Tweet.self)} )
                    completion(jobs)
                } else {
                    completion([])
                }
            }
        } else {
            completion([])
        }
    }
    func getPossibleLocations(country: String, withState state: String, completion: @escaping([Location]) -> Void){
        if !country.isEmpty {
            var query = db.collection("jobs").document(country).collection("jobs").order(by: "place").limit(to: 15)
            
            if !state.isEmpty {
                query = db.collection("jobs").document(country).collection("jobs").document(state).collection("jobs").order(by: "place").limit(to: 15)
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
    func getFarAway(country: String, avoid: String, completion: @escaping([Tweet], String) -> Void){
        if !country.isEmpty {
            let query = db.collection("jobs").document(country).collection("jobs")
            query.limit(to: 2)
                .getDocuments { snapshot, error in
                    if let documents = snapshot?.documents {
                        if documents.isEmpty {
                            completion([], "")
                        } else {
                            var name = documents[0].documentID
                            if name == avoid {
                                if documents.count == 1 {
                                    completion([], "")
                                    return
                                } else {
                                    name = documents[1].documentID
                                }
                            }
                            query.document(name).collection("jobs").limit(to: 1)
                                .getDocuments { snapshot, error in
                                    if let documents = snapshot?.documents, let city = documents.first?.documentID {
                                        query.document(name).collection("jobs").document(city).collection("jobs").limit(to: 12)
                                            .getDocuments { snapshot, error in
                                                if let documents = snapshot?.documents {
                                                    let jobs = documents.compactMap({ try? $0.data(as: Tweet.self)} )
                                                    completion(jobs, "\(city), \(name)")
                                                } else {
                                                    completion([], "")
                                                }
                                            }
                                    } else {
                                        completion([], "")
                                    }
                                }
                        }
                    } else { completion([], "") }
                }
        } else { completion([], "") }
    }
    func fetchRemoteJobs(completion: @escaping([Tweet]) -> Void){
        var jobs: [Tweet] = []
        db.collection("remote").order(by: "timestamp", descending: true).limit(to: 25).getDocuments { querySnapshot, error in
            if error == nil{
                guard let documents = querySnapshot?.documents else { return }
                jobs = documents.compactMap{ document -> Tweet? in
                    do {
                        return try document.data(as: Tweet.self)
                    } catch{
                        return nil
                    }
                }
                completion(jobs)
            }
        }
    }
    func fetchRemoteJobsAfter(lastdoc: Timestamp, completion: @escaping([Tweet]) -> Void){
        var jobs: [Tweet] = []
        db.collection("remote").whereField("timestamp", isLessThan: lastdoc).order(by: "timestamp", descending: true).limit(to: 25).getDocuments { querySnapshot, error in
            if error == nil{
                guard let documents = querySnapshot?.documents else { return }
                jobs = documents.compactMap{ document -> Tweet? in
                    do {
                        return try document.data(as: Tweet.self)
                    } catch{
                        return nil
                    }
                }
                completion(jobs)
            }
        }
    }
    func uploadZipToDatabase(forZip zip: String){
        if !zip.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            db.collection("users").document(uid).updateData(["zipCode": zip]){ _ in }
        }
    }
    func deleteJob(withId: String, location: String?){
        if !withId.isEmpty {
            if let loc = location {
                let substrings = loc.split(separator: ",")
                let country = String(substrings[0])
                let state = String(substrings[1])
                let city = String(substrings[2])
                
                if state.isEmpty {
                    db.collection("jobs").document(country).collection("jobs").document(city).collection("jobs").document(withId).delete()
                } else {
                    db.collection("jobs").document(country).collection("jobs").document(state).collection("jobs").document(city).collection("jobs").document(withId).delete()
                }
            } else {
                db.collection("remote").document(withId).delete()
            }
        }
    }
    func IncCompletedJobs(withUid userid: String?){
        if let id = userid, !id.isEmpty {
            db.collection("users").document(id).updateData(["completedjobs": FieldValue.increment(Int64(1))]) { _ in }
        }
    }
    func IncBought(userid: String?){
        if let id = userid, !id.isEmpty {
            db.collection("users").document(id).updateData(["bought": FieldValue.increment(Int64(1))]) { _ in }
        }
    }
    func IncSold(){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if !uid.isEmpty {
            db.collection("users").document(uid).updateData(["sold": FieldValue.increment(Int64(1))]) { _ in }
        }
    }
    func CheckJobExists(withId: String, location: String?, completion: @escaping(Bool) -> Void){
        if !withId.isEmpty {
            var query = db.collection("remote").document(withId)
            
            if let loc = location {
                let substrings = loc.split(separator: ",")
                let country = String(substrings[0])
                let state = String(substrings[1])
                let city = String(substrings[2])
                
                query = db.collection("jobs").document(country).collection("jobs").document(city).collection("jobs").document(withId)
                
                if !state.isEmpty {
                    query = db.collection("jobs").document(country).collection("jobs").document(state).collection("jobs").document(city).collection("jobs").document(withId)
                }
            }

            query
                .getDocument { snapshot, error in
                    guard let snapshot = snapshot else {
                        completion(false)
                        return
                    }
                    completion(snapshot.exists ? true : false)
                }
        } else {
            completion(false)
        }
    }
    func updateUserCountry(country: String){
        if !country.isEmpty {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            db.collection("users").document(uid).updateData([ "userCountry": country ]) { _ in }
        }
    }
}

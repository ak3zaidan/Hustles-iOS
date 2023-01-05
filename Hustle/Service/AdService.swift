import Firebase
import UIKit

struct AdService {
    func uploadAd(caption: String, start: Date, end: Date, webLink: String?, appName: String?, image: UIImage?, plus: Bool, photo: String, username: String, videoURL: String, completion: @escaping(Bool) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docID = "\(UUID())"
        var data = ["uid": uid,
                    "caption": caption,
                    "start": Timestamp(date: start),
                    "end": Timestamp(date: end),
                    "likes": 0,
                    "comments": 0,
                    "plus": plus,
                    "username": username,
                    "timestamp": Timestamp(date: Date())] as [String : Any]
        if let app = appName {
            data["tag"] = app
        }
        if !photo.isEmpty {
            data["profilephoto"] = photo
        }
        if let link = webLink {
            data["web"] = link
        }
        if !videoURL.isEmpty{
            data["video"] = videoURL
        }
        if let image = image{
            ImageUploader.uploadImage(image: image, location: "ads", compression: 0.5) { adImage, bool in
                if !bool {
                    completion(false)
                    return
                }
                data["image"] = adImage
                Firestore.firestore().collection("ads").document(docID)
                    .setData(data) { error in
                        if error != nil {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
            }
        } else {
            Firestore.firestore().collection("ads").document(docID)
                .setData(data) { error in
                    if error != nil {
                        completion(false)
                        return
                    }
                    completion(true)
                }
        }
    }
    func getAds(completion: @escaping([Tweet]) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("ads")
            .whereField("uid", isEqualTo: uid)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let ads = documents.compactMap({ try? $0.data(as: Tweet.self)} )
                completion(ads.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }) )
            }
    }
}


class AdsManager: ObservableObject{
    @Published var ads = [Tweet]()
    
    init(){
        getAds()
    }
    
    func getAds(){
        fetchAd { ads in
            if ads.isEmpty {
                self.fetchAd { adsSec in
                    self.ads = adsSec
                }
            } else {
                self.ads = ads
            }
        }
    }
    func fetchAd(completion: @escaping([Tweet]) -> Void){
        let start = Timestamp(date: Date())
        
        let query = Firestore.firestore().collection("ads").whereField("start", isLessThanOrEqualTo: start).limit(to: 15)
        query.getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            var tweets = documents.compactMap({ try? $0.data(as: Tweet.self)} )
            tweets.sort { $0.plus ?? true && !($1.plus ?? false) }
            completion(tweets)
        }
    }
}

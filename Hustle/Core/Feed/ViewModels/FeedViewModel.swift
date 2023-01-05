import Foundation
import Firebase
import FirebaseFirestore
import SwiftUI

class FeedViewModel: ObservableObject {
    @Published var new = [Tweet]()
    @Published var followers = [Tweet]()
    @Published var audio = [Tweet]()
    @Published var suggestedFollow = [User]()
    @Published var locations: [(String, [Tweet])] = []
    @Published var showProfile: Bool = false
    @Published var recentPhotos: [String] = ["", "", ""]
    @Published var viewedPosts = [String]()
    @Published var votedPosts = [String]()
    var firstVideo = [String : String]()
    var refreshedHustles = [String : Date]()
    var noPostsFromFollowers = false
    var noAudioPosts = false
    
    let service = TweetService()
  
    init(){
        fetchNew(blocked: [])
    }
  
    func fetchNew(blocked: [String]){
        service.fetchNew(newest: newestForYouPost()) { tweets in
            var temp = tweets
            blocked.forEach { element in
                temp.removeAll(where: { $0.uid == element })
            }
            
            temp = self.sortArrayWithPromotionPriority(array: temp)
            
            temp.reversed().forEach { element in
                if !self.new.contains(where: { $0.id == element.id }) {
                    withAnimation(.easeInOut(duration: 0.2)){
                        self.new.insert(element, at: 0)
                    }
                }
            }
            
            self.setImages(temp: temp)
        }
    }
    func fetch25MoreNew(blocked: [String], ads: [Tweet]){
        if let currentOldest = oldestForYouPost() {
            service.fetchNewMore(lastdoc: currentOldest) { tweets in
                if !tweets.isEmpty {
                    var temp = tweets
                    blocked.forEach { element in
                        temp.removeAll(where: { $0.uid == element })
                    }
                    
                    temp = self.sortArrayWithPromotionPriority(array: temp)

                    temp.forEach { element in
                        if !self.new.contains(where: { $0.id == element.id }) {
                            withAnimation(.easeInOut(duration: 0.2)){
                                self.new.append(element)
                            }
                        }
                    }
                    
                    self.setImages(temp: temp)
                }
            }
        }
    }
    func fetchFollowers(following: [String]){
        if !following.isEmpty {
            service.fetchFollowers(newest: newestFollowerPost(), following: following) { hustles in

                if self.followers.isEmpty {
                    self.noPostsFromFollowers = hustles.isEmpty
                }
                
                hustles.reversed().forEach { element in
                    if !self.followers.contains(where: { $0.id == element.id }) {
                        withAnimation(.easeInOut(duration: 0.2)){
                            self.followers.insert(element, at: 0)
                        }
                    }
                }
                
                self.setImages(temp: hustles)
            }
        } else {
            self.noPostsFromFollowers = true
        }
        
        getSuggested()
    }
    func fetchMoreFollowers(following: [String]) {
        if let oldest = oldestFollowerPost(), !following.isEmpty {
            service.fetchFollowersMore(following: following, lastdoc: oldest) { tweets in
                if !tweets.isEmpty {
                    
                    tweets.forEach { element in
                        if !self.followers.contains(where: { $0.id == element.id }) {
                            withAnimation(.easeInOut(duration: 0.2)){
                                self.followers.append(element)
                            }
                        }
                    }
                    
                    self.setImages(temp: tweets)
                }
            }
        }
    }
    func fetchAudio(blocked: [String]){
        service.fetchAudioPosts(newest: newestAudioPost()) { tweets in
            if tweets.isEmpty && self.audio.isEmpty {
                self.noAudioPosts = true
            } else {
                self.noAudioPosts = false
            }
            
            var temp = tweets
            blocked.forEach { element in
                temp.removeAll(where: { $0.uid == element })
            }
            
            temp = self.sortArrayWithPromotionPriority(array: temp)
            
            temp.reversed().forEach { element in
                if !self.audio.contains(where: { $0.id == element.id }) {
                    withAnimation(.easeInOut(duration: 0.2)){
                        self.audio.insert(element, at: 0)
                    }
                }
            }
            
            self.setImages(temp: temp)
        }
    }
    func fetchMoreAudio(blocked: [String]){
        if let currentOldest = oldestAudioPost() {
            service.fetchAudioPostsMore(lastdoc: currentOldest) { tweets in
                if !tweets.isEmpty {
                    var temp = tweets
                    blocked.forEach { element in
                        temp.removeAll(where: { $0.uid == element })
                    }
                    
                    temp = self.sortArrayWithPromotionPriority(array: temp)

                    temp.forEach { element in
                        if !self.audio.contains(where: { $0.id == element.id }) {
                            withAnimation(.easeInOut(duration: 0.2)){
                                self.audio.append(element)
                            }
                        }
                    }
                    
                    self.setImages(temp: temp)
                }
            }
        }
    }
    func setImages(temp: [Tweet]) {
        for i in 0..<temp.count {
            if let image = temp[i].profilephoto, !image.isEmpty {
                if self.recentPhotos[0].isEmpty {
                    self.recentPhotos[0] = image
                } else if self.recentPhotos[1].isEmpty {
                    if image != self.recentPhotos[0] {
                        self.recentPhotos[1] = image
                    }
                } else if self.recentPhotos[2].isEmpty {
                    if image != self.recentPhotos[0] && image != self.recentPhotos[1] {
                        self.recentPhotos[2] = image
                    }
                } else {
                    return
                }
            }
        }
    }
    func oldestForYouPost() -> Timestamp? {
        let oldest = self.new.min(by: { hustle1, hustle2 in
            return hustle1.timestamp.dateValue() < hustle2.timestamp.dateValue()
        })?.timestamp
        
        return oldest
    }
    func newestForYouPost() -> Timestamp? {
        let newest = self.new.max(by: { hustle1, hustle2 in
            return hustle1.timestamp.dateValue() < hustle2.timestamp.dateValue()
        })?.timestamp
        
        return newest
    }
    func oldestFollowerPost() -> Timestamp? {
        let oldest = self.followers.min(by: { hustle1, hustle2 in
            return hustle1.timestamp.dateValue() < hustle2.timestamp.dateValue()
        })?.timestamp
        
        return oldest
    }
    func newestFollowerPost() -> Timestamp? {
        let newest = self.followers.max(by: { hustle1, hustle2 in
            return hustle1.timestamp.dateValue() < hustle2.timestamp.dateValue()
        })?.timestamp
        
        return newest
    }
    func oldestAudioPost() -> Timestamp? {
        let oldest = self.audio.min(by: { hustle1, hustle2 in
            return hustle1.timestamp.dateValue() < hustle2.timestamp.dateValue()
        })?.timestamp
        
        return oldest
    }
    func newestAudioPost() -> Timestamp? {
        let newest = self.audio.max(by: { hustle1, hustle2 in
            return hustle1.timestamp.dateValue() < hustle2.timestamp.dateValue()
        })?.timestamp
        
        return newest
    }
    func getSuggested(){
        if suggestedFollow.isEmpty {
            service.fetchSuggested { users in
                users.forEach { user in
                    if !self.suggestedFollow.contains(where: { $0.id == user.id }) {
                        self.suggestedFollow.append(user)
                    }
                }
            }
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
    func fetchLocation(city: String, country: String){
        let place = "\(city), \(country)"
        if locations.firstIndex(where: { $0.0 == place }) != nil {
            return
        } else {
            service.fetchLocation(city: city) { hustles in
                self.locations.append((place, hustles))
            }
        }
    }
    func sortTop(place: String){
        if let index = locations.firstIndex(where: { $0.0 == place }) {
            locations[index].1.sort { $0.likes?.count ?? 0 > $1.likes?.count ?? 0 }
        }
    }
    func sortRecent(place: String){
        if let index = locations.firstIndex(where: { $0.0 == place }) {
            locations[index].1.sort { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
        }
    }
}

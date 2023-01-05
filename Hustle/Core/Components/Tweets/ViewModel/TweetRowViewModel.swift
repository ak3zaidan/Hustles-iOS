import Foundation
import Firebase

class TweetRowViewModel: ObservableObject {
    private let service =  TweetService()
    
    func likeTweet(tweet: Tweet){
        service.likeTweet(tweet)
    }
    func unlikeTweet(tweet: Tweet){
        service.unlikeTweet(tweet)
    }
    func deleteHustle(tweet: Tweet){
        service.deleteHustle(hustle: tweet)
        tweet.contentArray?.forEach({ element in
            ImageUploader.deleteImage(fileLocation: element) { _ in }
        })
        if let url = tweet.audioURL {
            ImageUploader.deleteImage(fileLocation: url) { _ in }
        }
    }
    func verify(good: Bool, elo: Int?, tweet: Tweet){
        var amount = 0
        if let elo = elo {
            if good {
                if elo < 600 { amount = 100 }
                else if elo < 850{ amount = 75 }
                else if elo < 1300{ amount = 50 }
                else if elo < 2000{ amount = 25 }
                else if elo < 2900{ amount = 12 }
                else if elo >= 2900 { amount = 6 }
            } else { amount = -50 }
        } else {
            if good { amount = 25 }
            else { amount = -50 }
        }
        service.verifyHustle(id: tweet.id, good: good, uid: tweet.uid, amount: amount)
    }
}

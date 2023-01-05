import Foundation

struct Profile {
    var user: User
    var tweets: [Tweet]?
    var listJobs: [Jobs]?
    var likedTweets: [Tweet]?
    var forSale: [Shop]?
    var questions: [Question]?
    var stories: [Story]?
    var lastUpdatedStories: Date? = nil
    var storyIndex = 0
}

struct Jobs: Decodable, Identifiable {
    var id: String
    var remote: Bool
    var job: Tweet
}

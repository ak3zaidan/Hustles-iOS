import Foundation
import LinkPresentation
import SwiftUI
import AVFoundation

class PopToRoot: ObservableObject {
    @Published var allMemories = [MemoryMonths]()
    @Published var noMoreMemories: Bool = false
    @Published var triedToFetchAsyncHighlights: Bool = false
    var savedMemories = [String]()
    
    @Published var hideTabBar: Bool = false
    @Published var tab: Int = 1
    
    @Published var showCopy: Bool = false
    @Published var TextToCopy: String = ""
    
    @Published var showImage: Bool = false
    @Published var image: String = ""
    
    @Published var showImageMessage: Bool = false
    @Published var realImage: Image?
    
    @Published var show: Bool = false
    
    @Published var tap: Int = 0

    @Published var displayingGroup: Bool = false
    
    @Published var hiddenMessage: String = ""
    
    @Published var messageToDelete: Bool = false
    
    @Published var Job_or_Shop: Bool = false
    
    @Published var Explore_or_Video: Bool = true
    @Published var Hide_Video: Bool = true
    
    @Published var cachedMetadata: [URL: LPLinkMetadata] = [:]
    
    @Published var snapImage: UIImage?
    @Published var focusLocation: (CGFloat, CGFloat)?
    
    @Published var showStories: Bool = false
    @Published var showFriends: Bool = false
    
    @Published var likedHustles: [String] = []
    @Published var unlikedHustles: [String] = []
    
    @Published var lastSeen: Date? = nil
    
    @Published var invitedFriends: [String] = []
    
    @Published var audioFiles: [(String, URL)] = []
    
    @Published var currentAudio: String = ""
    @Published var tempCurrentAudio: String = ""
    @Published var muted: Bool = true
    @Published var player: AVPlayer? = nil
    @Published var playID: String = ""
    
    @Published var chatSentAlert: Bool = false
    @Published var chatSentError: Bool = false
    @Published var chatAlertID: String = ""
    
    @Published var showAlert: Bool = false
    @Published var alertReason: String = ""
    var alertID: String = ""
    @Published var alertImage: String = ""
    
    @Published var showAlertSmall: Bool = false
    @Published var alertReasonSmall: String = ""
    @Published var alertIDSmall: String = ""
    
    @Published var dimTab: Bool = false
    
    @Published var randomMemories: [Memory] = []
    @Published var randomUsers: [User] = []
    @Published var randomTweets: [Tweet] = []
    @Published var randomStories: [Story] = []
    @Published var randomUserStories: [(String, [Story])] = []
    
    @Published var saveImageAnim: String = ""
    
    @Published var currentSound: String = ""
    
    @Published var transcriptions: [(String, String)] = []
    @Published var updatedView: [(String, Int, Int, [String])] = []
    @Published var previewStory: [String : Image] = [:]
    
    var timeSinceLastStoryUpdate: Date? = nil
    var storyTitles: [String : String] = [:]
    
    var trendingHashtags = [String]()
    
    @Published var uploadRate: Double? = nil
    
    @Published var newsMid: String = ""
    @Published var isNewsExpanded: Bool = false
    var selectedNewsID: String = ""
    var lastFetchedStocks: Date? = nil
    
    func uploadTweet(withCaption caption: String, withPro promoted: Int, userPhoto: String, username: String, videoLink: String, content: [uploadContent], userVeri: Bool?, audioURL: URL?, sloc: String?, bloc: String?, lat: Double?, long: Double?, choice1: String?, choice2: String?, choice3: String?, choice4: String?, fullname: String, yelpID: String?, newsID: String?, background: Bool, reduceAmount: Int?, completion: @escaping(Bool) -> Void){
        let link = inputChecker().getLink(videoLink: videoLink)
        
        if background {
            self.uploadRate = 0.01
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                self.recursiveAddTime()
            }
        }
        
        TweetService().uploadTweet(caption: caption, promoted: promoted, photo: userPhoto, username: username, videoLink: link, content: content, userVeri: userVeri, audioURL: audioURL, sloc: sloc, bloc: bloc, lat: lat, long: long, choice1: choice1, choice2: choice2, choice3: choice3, choice4: choice4, fullname: fullname, yelpID: yelpID, newsID: newsID) { success in
            completion(success)
            
            if background {
                if success {
                    if let reduceAmount {
                        UserService().editElo(withUid: nil, withAmount: reduceAmount) {}
                    }
                    
                    self.alertReason = "Post Uploaded!"
                    self.alertImage = "checkmark"
                    withAnimation(.easeInOut(duration: 0.2)){ self.showAlert = true }
                    
                    withAnimation { self.uploadRate = 1.0 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation { self.uploadRate = nil }
                    }
                } else {
                    self.alertReason = "Error uploading post"
                    self.alertImage = "exclamationmark.triangle.fill"
                    withAnimation(.easeInOut(duration: 0.2)){ self.showAlert = true }
                    
                    withAnimation { self.uploadRate = 0.0 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation { self.uploadRate = nil }
                    }
                }
            }
        }
    }
    func recursiveAddTime() {
        if let uploadRate {
            withAnimation(.easeInOut(duration: 0.4)){
                var end = false
                
                if uploadRate == 0.01 {
                    self.uploadRate = 0.25
                } else if uploadRate == 0.25 {
                    self.uploadRate = 0.5
                } else if uploadRate == 0.5 {
                    self.uploadRate = 0.7
                } else if uploadRate == 0.7 {
                    self.uploadRate = 0.8
                } else if uploadRate == 0.8 {
                    self.uploadRate = 0.85
                } else if uploadRate == 0.85 {
                    self.uploadRate = 0.9
                } else if uploadRate == 0.9 {
                    self.uploadRate = 0.925
                } else {
                    end = true
                }
                
                if !end {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        self.recursiveAddTime()
                    }
                }
            }
        }
    }
}

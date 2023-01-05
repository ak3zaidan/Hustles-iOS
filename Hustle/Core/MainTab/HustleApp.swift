import SwiftUI
import Firebase
import AVFoundation
import UIKit
import CoreData

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: .duckOthers)
        } catch {
            print("Error setting AVAudioSession")
        }
        
        return true
    }
}

@main
struct HustleApp: App {
    @StateObject var viewModel = AuthViewModel()
    @StateObject var feed = FeedViewModel()
    @StateObject var messageViewModel = MessageViewModel()
    @StateObject var groupChatViewModel = GroupChatViewModel()
    @StateObject var exploreViewModel = ExploreViewModel()
    @StateObject var groupViewModel = GroupViewModel()
    @StateObject var userViewModel = ProfileViewModel()
    @StateObject var commentViewModel = CommentViewModel()
    @StateObject var popRoot = PopToRoot()
    @StateObject var adsManager = AdsManager()
    @StateObject var uploadAds = UploadAdViewModel()
    @StateObject var questions = QuestionModel()
    @StateObject var Jobs = JobViewModel()
    @StateObject var Shop = ShopViewModel()
    @StateObject var video = VideoModel()
    @StateObject var stocks = StockViewModel()
    @StateObject var AI = AIHistory()
    @StateObject var AI2 = ViewModel()
    @StateObject var Globe = GlobeViewModel()
    @StateObject var city = CitySearchViewModel()
    @StateObject var places = AddressSearchViewModel()
    @StateObject var videoComment = VideoCommentModel()
    @StateObject var questionComment = QuestionCommentModel()
    @StateObject var mapModel = LocationsViewModel()
    @StateObject var audioR = AudioRecorder(numberOfSamples: 80, audioFormatID: kAudioFormatAppleLossless, audioQuality: .max)
    @StateObject var audioG = AudioRecorderG(numberOfSamples: 80, audioFormatID: kAudioFormatAppleLossless, audioQuality: .max)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(messageViewModel)
                .environmentObject(exploreViewModel)
                .environmentObject(groupViewModel)
                .environmentObject(userViewModel)
                .environmentObject(commentViewModel)
                .environmentObject(popRoot)
                .environmentObject(adsManager)
                .environmentObject(uploadAds)
                .environmentObject(questions)
                .environmentObject(Jobs)
                .environmentObject(Shop)
                .environmentObject(video)
                .environmentObject(feed)
                .environmentObject(stocks)
                .environmentObject(AI)
                .environmentObject(AI2)
                .environmentObject(Globe)
                .environmentObject(city)
                .environmentObject(videoComment)
                .environmentObject(questionComment)
                .environmentObject(audioR)
                .environmentObject(audioG)
                .environmentObject(groupChatViewModel)
                .environmentObject(places)
                .environmentObject(mapModel)
        }
    }
}

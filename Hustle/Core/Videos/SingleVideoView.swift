import SwiftUI
import WebKit
import UIKit

enum DragState: Equatable {
    case inactive
    case pressing
    case dragging(translation: CGSize)

    var translation: CGSize {
        switch self {
        case .inactive, .pressing:
            return .zero
        case .dragging(let translation):
            return translation
        }
    }
    var isDragging: Bool {
        switch self {
        case .dragging:
            return true
        case .pressing, .inactive:
            return false
        }
    }
    var isPressing: Bool {
        switch self {
        case .inactive:
            return false
        case .pressing, .dragging:
            return true
        }
    }
}

struct SingleVideoView: View {
    let link: String
    @State private var viewIsShowing = false
    @State private var isVideoPlaying = false
    @State private var isChangingTime = false
    @State private var currentTime = 0.0
    @State private var totalLength = 1.0
    @GestureState private var dragState = DragState.inactive
    @State private var fillCircles = 0
    @State private var startDragTime = 0.0
    @EnvironmentObject var viewModel: VideoModel
    @EnvironmentObject var popRoot: PopToRoot
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack {
            Color.black
            
            SmartReelView(link: link, isPlaying: $isVideoPlaying, isChangingTime: $isChangingTime, totalLength: $totalLength, currentTime: $currentTime, viewIsShowing: $viewIsShowing)

            Button("", action: {}).disabled(true)
            
            Color.gray.opacity(0.001)
                .onTapGesture {
                    isVideoPlaying.toggle()
                }
                .gesture(LongPressGesture(minimumDuration: 0.01)
                    .sequenced(before: DragGesture().onEnded({ _ in
                        isVideoPlaying = true
                        isChangingTime = false
                    }))
                    .updating(self.$dragState, body: { (value, dstate, _) in
                        switch value {
                        case .first:
                            dstate = .pressing
                        case .second(true, let drag):
                            dstate = .dragging(translation: drag?.translation ?? .zero)
                        default:
                            break
                        }
                    })
                )
            if (dragState.isPressing || dragState.isDragging) && totalLength != 1.0 {
                ZStack(alignment: .center){
                    RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial)
                    HStack {
                        Text("0:00").foregroundColor(.white).font(.subheadline)
                        Spacer()
                        ZStack(alignment: .leading){
                            HStack(alignment: .center, spacing: 1) {
                                ForEach(0..<50, id: \.self) { _ in
                                    Circle().frame(width: 4, height: 4)
                                        .foregroundColor(.black)
                                }
                            }
                            HStack(alignment: .center, spacing: 1) {
                                ForEach(0..<fillCircles, id: \.self) { _ in
                                    Circle().frame(width: 4, height: 4)
                                        .foregroundColor(.white)
                                }

                            }
                            VStack(alignment: .leading, spacing: 2){
                                Text(formatTime(seconds: currentTime)).foregroundColor(.white).font(.caption).offset(x: -12)
                                Rectangle().foregroundColor(.blue).frame(width: 1, height: 25)
                                Spacer()
                            }.offset(x: CGFloat(fillCircles * 5)).padding(.top, 6)
                        }
                        Spacer()
                        Text(formatTime(seconds: totalLength)).foregroundColor(.white).font(.subheadline)
                    }.padding(.horizontal, 10)
                }
                .frame(width: widthOrHeight(width: true) * 0.95, height: 80).offset(y: -widthOrHeight(width: false) * 0.22)
                .onDisappear {
                    isVideoPlaying = true
                    isChangingTime = false
                }
            }
        }
        .ignoresSafeArea()
        .onDisappear {
            isVideoPlaying = false
            viewIsShowing = false
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active && viewModel.selected == link && !popRoot.Explore_or_Video {
                viewIsShowing = true
                isVideoPlaying = true
            } else if newPhase == .inactive {
                isVideoPlaying = false
                viewIsShowing = false
            } else if newPhase == .background {
                isVideoPlaying = false
                viewIsShowing = false
            }
        }
        .onAppear {
            if viewModel.selected == link && !popRoot.Explore_or_Video {
                viewIsShowing = true
                isVideoPlaying = true
            }
        }
        .onChange(of: viewModel.selected, perform: { _ in
            if viewModel.selected == link && !popRoot.Explore_or_Video {
                viewIsShowing = true
                isVideoPlaying = true
            } else if viewModel.selected != link {
                viewIsShowing = false
                isVideoPlaying = false
            }
        })
        .onChange(of: popRoot.Explore_or_Video, perform: { _ in
            if popRoot.Explore_or_Video {
                isVideoPlaying = false
                viewIsShowing = false
            } else if viewModel.selected == link {
                viewIsShowing = true
                isVideoPlaying = true
            }
        })
        .onChange(of: dragState) { _ in
            let speed: CGFloat = 100
            if (!dragState.isDragging) {
                startDragTime = currentTime
            }
            if (dragState.isPressing || dragState.isDragging) && totalLength != 1.0 {
                isVideoPlaying = false
                let translation = dragState.translation.width
                if translation > 5 {
                    isChangingTime = true
                    let timeLeft = totalLength - startDragTime
                    let changeRatio = ((translation / speed) > 1) ? 1 : (translation / speed)
                    let timeToAdd = changeRatio * timeLeft
                    currentTime = startDragTime + timeToAdd
                } else if translation < -5 {
                    isChangingTime = true
                    let changeRatio = ((abs(translation) / speed) > 1) ? 1 : (abs(translation) / speed)
                    let timeToSubtract = changeRatio * startDragTime
                    currentTime = startDragTime - timeToSubtract
                }
            }
        }
        .onChange(of: currentTime) { _ in
            fillCircles = Int((currentTime / totalLength) * 50)
        }
    }
    func formatTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60

        if minutes < 1 {
            return String(format: "0:%02d", remainingSeconds)
        } else {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
}

struct SmartReelView: UIViewRepresentable {
    let link: String
    @Binding var isPlaying: Bool
    @Binding var isChangingTime: Bool
    @Binding var totalLength: Double
    @Binding var currentTime: Double
    @Binding var viewIsShowing: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "observe")

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.userContentController = userContentController

        let webview = WKWebView(frame: .zero, configuration: webConfiguration)
        webview.navigationDelegate = context.coordinator
        
        webview.backgroundColor = .clear
        webview.isOpaque = false

        loadInitialContent(web: webview)
        
        return webview
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        var jsString = """
        isPlaying = \((isPlaying) ? "true" : "false");
        watchPlayingState();
        """
        if isChangingTime {
            jsString = """
            isPlaying = \((isPlaying) ? "true" : "false");
            watchPlayingState();
            seekToTime(\(currentTime));
            """
        }
        uiView.evaluateJavaScript(jsString, completionHandler: nil)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler  {
        var parent: SmartReelView

        init(_ parent: SmartReelView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage){
            if let body = message.body as? [String: Any] {
                if let name = body["name"] as? String, let value = body["body"] as? Double {
                    if name == "totalLength" {
                        parent.totalLength = value
                    } else if name == "currentTime" {
                        parent.currentTime = value
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if self.parent.viewIsShowing {
                webView.evaluateJavaScript("clickReady()", completionHandler: nil)
                Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                    webView.evaluateJavaScript("clickReadySec()", completionHandler: nil)
                }
                Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                    webView.evaluateJavaScript("clickReadySec()", completionHandler: nil)
                }
            }
        }
    }
    
    private func loadInitialContent(web: WKWebView) {
        let embedHTML = """
        <style>
            body {
                margin: 0;
                background-color: black;
            }
            .iframe-container iframe {
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
            }
        </style>
        <div class="iframe-container">
            <div id="player"></div>
        </div>
        <script>
            var tag = document.createElement('script');
            tag.src = "https://www.youtube.com/iframe_api";
            var firstScriptTag = document.getElementsByTagName('script')[0];
            firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

            var player;
            var isPlaying = false;
            var ready = false;
            function onYouTubeIframeAPIReady() {
                player = new YT.Player('player', {
                    width: '100%',
                    videoId: '\(link.dropLast(4))',
                    playerVars: { 'playsinline': 1, 'controls': 0},
                    events: {
                        'onStateChange': function(event) {
                            if (event.data === YT.PlayerState.ENDED) {
                                player.seekTo(0);
                                player.playVideo();
                            }
                        },
                        'onReady': function() {
                            ready = true;

                            setTimeout(function() {
                                getLength();
                            }, 4000);
                        }
                    }
                });
            }
            function clickReady() {
                if (ready) {
                    player.playVideo();
                }
            }
            function clickReadySec() {
                if (ready) {
                    var videoState = player.getPlayerState();
                    if (videoState !== YT.PlayerState.PLAYING) {
                        player.playVideo();
                    }
                }
            }
            function getLength() {
                const length = player.getDuration();
        
                const message = {
                    name: "totalLength",
                    body: length
                };
        
                window.webkit.messageHandlers.observe.postMessage(message);
        
                setInterval(function() {
                    if (isPlaying) {
                        var videoState = player.getPlayerState();
                        if (videoState === YT.PlayerState.PLAYING) {
                            const currentTime = player.getCurrentTime();
                
                            const message = {
                                name: "currentTime",
                                body: currentTime
                            };
                
                            window.webkit.messageHandlers.observe.postMessage(message);
                        }
                    }
                }, 2000);
            }
            function watchPlayingState() {
                if (isPlaying && ready) {
                    player.playVideo();
                } else {
                    player.pauseVideo();
                }
            }
            function seekToTime(seconds) {
                if (player && seconds > 0.0) {
                    player.seekTo(seconds);
                    timeToSeek = 0.0;
                }
            }
        </script>
        """
        
        web.scrollView.isScrollEnabled = false
        web.loadHTMLString(embedHTML, baseURL: nil)
    }
}

import SwiftUI
import WebKit

struct YouTubeView: UIViewRepresentable {
    let link: String
    let short: Bool
    @Environment(\.colorScheme) var colorScheme

    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        let webview = WKWebView(frame: .zero, configuration: webConfiguration)
        webview.backgroundColor = .clear
        webview.isOpaque = false
        return webview
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        var embedHTML = ""
        
        if short {
            let realLink = link.dropFirst(7)
            
            embedHTML = """
            <body style="background-color:\(colorScheme == .dark ? "black" : "white"); display: flex; justify-content: center; align-items: center;">
                <iframe
                width="500"
                height="950"
                src="https://www.youtube.com/embed/\(realLink)?autoplay=1" frameborder="0" allowfullscreen></iframe>
            </body>
            """
        } else {
            embedHTML = """
            <style>
                body {
                    margin: 0;
                    background-color: \(colorScheme == .dark ? "black" : "white");
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
                function onYouTubeIframeAPIReady() {
                    player = new YT.Player('player', {
                        width: '100%',
                        videoId: '\(link)',
                        playerVars: { 'playsinline': 1 },
                        events: {
                            'onStateChange': function(event) {
                                if (event.data === YT.PlayerState.ENDED) {
                                    player.seekTo(0);
                                    player.playVideo();
                                }
                            }
                        }
                    });
                }
            </script>
            """
        }
        
        uiView.scrollView.isScrollEnabled = false
        uiView.loadHTMLString(embedHTML, baseURL: nil)
    }
}

struct WebVideoView: UIViewRepresentable {
    let link: String
    @Environment(\.colorScheme) var colorScheme

    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        let webview = WKWebView(frame: .zero, configuration: webConfiguration)
        webview.backgroundColor = .clear
        webview.isOpaque = false
        return webview
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let html = """
        <body style="background-color:\(colorScheme == .dark ? "black" : "white");display: flex; justify-content: center;">
            <video
            src="\(link)"
            width="950" height="536"
            controls
            playsinline="true"
            autoplay>
        </body>
        """
        
        uiView.scrollView.isScrollEnabled = false
        uiView.loadHTMLString(html, baseURL: nil)
    }
}

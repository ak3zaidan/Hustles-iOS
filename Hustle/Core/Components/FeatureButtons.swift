import SwiftUI
import MarqueeText

struct AIButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            LottieView(loopMode: .loop, name: "finite")
                .scaleEffect(0.14)
                .frame(width: 85, height: 50)
            MarqueeText(
                 text: "        AI       - your virtual assistant, ask me anything.",
                 font: UIFont.preferredFont(forTextStyle: .subheadline),
                 leftFade: 16,
                 rightFade: 16,
                 startDelay: 3
                 )
        }
        .padding(13)
        .background(.gray.opacity(0.2))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(colorScheme == .dark ? .white : .black, lineWidth: 1).opacity(0.7)
        }
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .frame(width: 100)
    }
}

struct RandomChat: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            LottieView(loopMode: .loop, name: "randChat")
                .scaleEffect(0.4)
                .frame(width: 85, height: 50)
                .offset(y: -15)
            MarqueeText(
                 text: "Chat with strangers.",
                 font: UIFont.preferredFont(forTextStyle: .subheadline),
                 leftFade: 16,
                 rightFade: 16,
                 startDelay: 2
                 )
        }
        .padding(13)
        .background(content: {
            Color.gray.opacity(0.2).clipShape(RoundedRectangle(cornerRadius: 15))
        })
        .background {
            RoundedRectangle(cornerRadius: 15)
                .stroke(colorScheme == .dark ? .white : .black, lineWidth: 1).opacity(0.7)
        }
        .frame(width: 100)
    }
}

struct TrackStockButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            LottieView(loopMode: .loop, name: "trackS")
                .scaleEffect(0.6)
                .frame(width: 85, height: 50)
                .offset(y: -15)
            MarqueeText(
                 text: "Track Apple Stock Price",
                 font: UIFont.preferredFont(forTextStyle: .subheadline),
                 leftFade: 16,
                 rightFade: 16,
                 startDelay: 1
                 )
        }
        .padding(13)
        .background(content: {
            Color.gray.opacity(0.2).clipShape(RoundedRectangle(cornerRadius: 15))
        })
        .background {
            RoundedRectangle(cornerRadius: 15)
                .stroke(colorScheme == .dark ? .white : .black, lineWidth: 1).opacity(0.7)
        }
        .frame(width: 100)
    }
}

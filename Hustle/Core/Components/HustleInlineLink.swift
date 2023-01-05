import SwiftUI

private let linkDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

struct HustleInlineLink: View {
    let text: String
    let links: [NSTextCheckingResult]
    
    init (_ text: String) {
        self.text = text
        let nsText = text as NSString
        let wholeString = NSRange(location: 0, length: nsText.length)
        links = linkDetector.matches(in: text, options: [], range: wholeString)
    }
    
    var body: some View {
        HustleInlineLinkView(text: text, links: links)
    }
}

struct HustleInlineLinkView: View {
    @State var showProfile: Bool = false
    @State var selectedUser: String? = nil
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var popRoot: PopToRoot
    
    enum Component {
        case text(String)
        case link(String, URL)
        case username(String)
        case hashtag(String)
    }

    let text: String
    @State var components: [Component]

    init(text: String, links: [NSTextCheckingResult]) {
        self.text = text
        let nsText = text as NSString
        
        var components: [Component] = []
        var index = 0
        for result in links {
            if result.range.location > index {
                let sub_str = nsText.substring(with: NSRange(location: index, length: result.range.location - index))
                let ats = separateTextAndTags(input: sub_str)
                
                ats.forEach { element in
                    if element.hasPrefix("@") && element.count < 13 {
                        components.append(.username(element))
                    } else if element.hasPrefix("#") && element.count < 40 {
                        components.append(.hashtag(element))
                    } else {
                        components.append(.text(element))
                    }
                }
            }
            components.append(.link(nsText.substring(with: result.range), result.url!))
            index = result.range.location + result.range.length
        }
        if index < nsText.length {
            let sub_str = nsText.substring(from: index)
            let ats = separateTextAndTags(input: sub_str)
            
            ats.forEach { element in
                if element.hasPrefix("@") && element.count < 13 {
                    components.append(.username(element))
                } else if element.hasPrefix("#") && element.count < 40 {
                    components.append(.hashtag(element))
                } else {
                    components.append(.text(element))
                }
            }
        }
        _components = State(initialValue: components)
    }
    
    var body: some View {
        CustomLayout(spacing: 0){
            ForEach(Array(components.enumerated()), id: \.offset) { _, component in
                switch component {
                case .text(let text):
                    Text(verbatim: text).font(.subheadline).multilineTextAlignment(.leading)
                case .link(let text, _):
                    Button {
                        if let url = URL(string: text) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    } label: {
                        Text(verbatim: text).foregroundColor(.blue).font(.subheadline)
                            .multilineTextAlignment(.leading)
                    }
                    .contextMenu {
                        Button(action: {
                            if let url = URL(string: text) {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            }
                        }, label: {
                            Label("Open Link", systemImage: "arrow.up.forward.circle")
                        })
                    } preview: {
                        contextMenuLinkPreview(url: URL(string: text) ?? URL(string: "https://www.google.com")!)
                    }
                case .username(let text):
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        let charactersToRemove = CharacterSet(charactersIn: ".,")
                        self.selectedUser = text.replacingOccurrences(of: "@", with: "")
                        self.selectedUser = self.selectedUser?.trimmingCharacters(in: charactersToRemove)
                        if !(self.selectedUser ?? "").isEmpty {
                            showProfile = true
                        }
                    }, label: {
                        Text(text)
                            .font(.subheadline).bold()
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.orange)
                    })
                case .hashtag(let hash):
                    NavigationLink {
                        HashtagSearchView(hashtag: hash).enableFullSwipePop(true)
                    } label: {
                        Text(hash)
                            .italic()
                            .font(.subheadline).bold()
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                ProfileSheetView(uid: "", photo: "", user: nil, username: $selectedUser)
            }.presentationDetents([.large])
        }
    }
}

func separateTextAndTags(input: String) -> [String] {
    var resultArray: [String] = []
    var currentToken = ""

    for character in input {
        if character == "@" || character == "#" {
            if !currentToken.isEmpty {
                resultArray.append(currentToken)
                currentToken = ""
            }
            currentToken += String(character)
        } else if character.isWhitespace {
            if currentToken.count > 1 && (currentToken.hasPrefix("@") || currentToken.hasPrefix("#")) {
                resultArray.append(currentToken)
                currentToken = ""
            }
            currentToken += String(character)
        } else {
            currentToken += String(character)
        }
    }

    if !currentToken.isEmpty {
        resultArray.append(currentToken)
    }

    return resultArray
}

extension [LayoutSubviews.Element] {
    func maxHeight(_ proposal: ProposedViewSize) -> CGFloat {
        return self.compactMap { view in
            return view.sizeThatFits(proposal).height
        }.max() ?? 0
    }
}

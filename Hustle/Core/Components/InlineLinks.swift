import SwiftUI

private let linkDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

struct LinkedTextG: View {
    let text: String
    let allP: [String]
    let links: [NSTextCheckingResult]
    
    init (_ text: String, allP: [String]) {
        self.text = text
        self.allP = allP
        let nsText = text as NSString
        let wholeString = NSRange(location: 0, length: nsText.length)
        links = linkDetector.matches(in: text, options: [], range: wholeString)
    }
    
    var body: some View {
        LinkColoredTextG(text: text, links: links, allPossible: allP)
    }
}

struct LinkColoredTextG: View {
    @State var showProfile: Bool = false
    @State var selectedUser: String? = nil
    @EnvironmentObject var group: GroupViewModel
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    enum Component {
        case text(String)
        case link(String, URL)
        case hashtag(String, String)
        case username(String, String)
    }

    let text: String
    let components: [Component]

    init(text: String, links: [NSTextCheckingResult], allPossible: [String]) {
        self.text = text
        let nsText = text as NSString
        
        var components: [Component] = []
        var index = 0
        for result in links {
            if result.range.location > index {
                let sub_str = nsText.substring(with: NSRange(location: index, length: result.range.location - index))
                
                if !findHashtags(in: sub_str, possible: allPossible) {
                    let ats = separateTextAndTags(input: sub_str)
                  
                    ats.forEach { element in
                        if element.hasPrefix("@") && element.count < 13 {
                            components.append(.username(element, element))
                        } else {
                            components.append(.text(element))
                        }
                    }
                } else {
                    var offset = 0
                    let fetched = getAll(inputString: sub_str, using: allPossible)
                    
                    for i in 0..<fetched.count {
                        if findHashtags(in: fetched[i], possible: allPossible) {
                            components.append(.hashtag(nsText.substring(with: NSRange(location: index + offset, length: fetched[i].count)), fetched[i]))
                        } else {
                            let sub_text = nsText.substring(with: NSRange(location: index + offset, length: fetched[i].count))
                            let ats = separateTextAndTags(input: sub_text)

                            ats.forEach { element in
                                if element.hasPrefix("@") && element.count < 13 {
                                    components.append(.username(element, element))
                                } else {
                                    components.append(.text(element))
                                }
                            }
                        }
                        offset += fetched[i].count
                    }
                }
            }
            components.append(.link(nsText.substring(with: result.range), result.url!))
            index = result.range.location + result.range.length
        }
        if index < nsText.length {
            let sub_str = nsText.substring(from: index)
            var offset = 0
            
            if !findHashtags(in: sub_str, possible: allPossible) {
                let ats = separateTextAndTags(input: sub_str)
                ats.forEach { element in
                    if element.hasPrefix("@") && element.count < 13 {
                        components.append(.username(element, element))
                    } else {
                        components.append(.text(element))
                    }
                }
            } else {
                let fetched = getAll(inputString: sub_str, using: allPossible)
                
                for i in 0..<fetched.count {
                    if findHashtags(in: fetched[i], possible: allPossible) {
                        components.append(.hashtag(nsText.substring(with: NSRange(location: index + offset, length: fetched[i].count)), fetched[i]))
                    } else {
                        let sub_text = nsText.substring(with: NSRange(location: index + offset, length: fetched[i].count))
                        let ats = separateTextAndTags(input: sub_text)
                        
                        ats.forEach { element in
                            if element.hasPrefix("@") && element.count < 13 {
                                components.append(.username(element, element))
                            } else {
                                components.append(.text(element))
                            }
                        }
                    }
                    offset += fetched[i].count
                }
            }
        }
        self.components = components
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
                case .hashtag(let text, _):
                    Button(action: {
                        var square = text.replacingOccurrences(of: "#", with: "")
                        square = square.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let index = group.currentGroup {
                            if let first = group.groups[index].1.squares?.first(where: { $0 == square }) {
                                group.groups[index].0 = first
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                
                                if let messages = group.groups[index].1.messages?.first(where: { $0.id == square }) {
                                    if messages.messages.isEmpty {
                                        group.beginGroupConvo(groupId: group.groups[index].1.id, devGroup: false, blocked: auth.currentUser?.blockedUsers ?? [], square: group.groups[index].0)
                                    }
                                } else {
                                    group.beginGroupConvo(groupId: group.groups[index].1.id, devGroup: false, blocked: auth.currentUser?.blockedUsers ?? [], square: group.groups[index].0)
                                }
                            } else if square == "Rules" {
                                group.groups[index].0 = "Rules"
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            } else if square == "Main" {
                                group.groups[index].0 = "Main"
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            } else if square == "Info/Description" {
                                group.groups[index].0 = "Info/Description"
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            } else if let sub = group.subContainers.first(where: { $0.0 == group.groups[index].1.id }) {
                                if sub.1.contains(where: { $0.sub.contains(square) }) {
                                    group.groups[index].0 = square
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    
                                    if let messages = group.groups[index].1.messages?.first(where: { $0.id == square }) {
                                        if messages.messages.isEmpty {
                                            group.beginGroupConvo(groupId: group.groups[index].1.id, devGroup: false, blocked: auth.currentUser?.blockedUsers ?? [], square: group.groups[index].0)
                                        }
                                    } else {
                                        group.beginGroupConvo(groupId: group.groups[index].1.id, devGroup: false, blocked: auth.currentUser?.blockedUsers ?? [], square: group.groups[index].0)
                                    }
                                }
                            }
                        }
                    }, label: {
                        Text(verbatim: text)
                            .font(.subheadline)
                            .foregroundColor(.white).bold().padding(.horizontal, 2)
                            .multilineTextAlignment(.leading)
                            .background(Color.purple.opacity(0.7)).cornerRadius(5, corners: .allCorners)
                    })
                case .username(let text, _):
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        let charactersToRemove = CharacterSet(charactersIn: ".,")
                        self.selectedUser = text.replacingOccurrences(of: "@", with: "")
                        self.selectedUser = self.selectedUser?.trimmingCharacters(in: charactersToRemove)
                        if !(self.selectedUser ?? "").isEmpty {
                            showProfile = true
                        }
                    }, label: {
                        Text(verbatim: text)
                            .font(.subheadline).bold().padding(.horizontal, 2)
                            .multilineTextAlignment(.leading)
                            .background(Color.orange.opacity(0.55)).cornerRadius(5, corners: .allCorners)
                    })
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

func findHashtags(in text: String, possible: [String]) -> Bool {
    var newSub = [String]()
    for i in 0..<possible.count {
        newSub.append("#\(possible[i])")
    }
    
    if newSub.contains(where: { text.contains($0) }) {
        return true
    }
    return false
}

func getAll(inputString: String, using substrings: [String]) -> [String] {
    var resultArray: [String] = []
    
    var newSub = [String]()
    for i in 0..<substrings.count {
        newSub.append("#\(substrings[i])")
    }

    let sortedSubstrings = newSub.sorted { $0.count > $1.count }

    var remainingString = inputString
    for substring in sortedSubstrings {
        if let range = remainingString.range(of: substring) {
            if range.lowerBound.utf16Offset(in: remainingString) > 0 {
                resultArray.append(String(remainingString[..<range.lowerBound]))
            }
            resultArray.append(substring)

            remainingString = String(remainingString[range.upperBound...])
        }
    }
    if !remainingString.isEmpty {
        resultArray.append(remainingString)
    }

    return resultArray
}

struct CustomLayout: Layout {
    struct CacheData {
        let rows: [[LayoutSubviews.Element]]
        let maxWidth: CGFloat
    }

    var alignment: Alignment = .leading
    var spacing: CGFloat = 0

    func makeCache(subviews: Subviews) -> CacheData {
        let maxWidth = subviews.reduce(0) { max($0, $1.sizeThatFits(.unspecified).width) }
        let rows = generateRows(maxWidth, .unspecified, subviews)
        
        return CacheData(rows: rows, maxWidth: maxWidth)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        let maxWidth = proposal.width ?? cache.maxWidth
        var height: CGFloat = 0
        let rows = cache.rows
        
        for (index, row) in rows.enumerated() {
            if index == (rows.count - 1) {
                height += row.maxHeight(proposal)
            } else {
                height += row.maxHeight(proposal) + spacing
            }
        }
        
        return .init(width: maxWidth, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
        var origin = bounds.origin
        let maxWidth = bounds.width
        let rows = cache.rows
        
        for row in rows {
            let leading: CGFloat = bounds.maxX - maxWidth
            let trailing = bounds.maxX - (row.reduce(CGFloat.zero) { partialResult, view in
                let width = view.sizeThatFits(proposal).width
                
                if view == row.last {
                    return partialResult + width
                }
                return partialResult + width + spacing
            })
            let center = (trailing + leading) / 2
            
            origin.x = (alignment == .leading ? leading : alignment == .trailing ? trailing : center)
            
            for view in row {
                let viewSize = view.sizeThatFits(proposal)
                view.place(at: origin, proposal: proposal)
                origin.x += (viewSize.width + spacing)
            }
        
            origin.y += (row.maxHeight(proposal) + spacing)
        }
    }
    
    func generateRows(_ maxWidth: CGFloat, _ proposal: ProposedViewSize, _ subviews: Subviews) -> [[LayoutSubviews.Element]] {
        var row: [LayoutSubviews.Element] = []
        var rows: [[LayoutSubviews.Element]] = []
        
        var origin = CGRect.zero.origin
        
        for view in subviews {
            let viewSize = view.sizeThatFits(proposal)
            
            if (origin.x + viewSize.width + spacing) > maxWidth {
                rows.append(row)
                row.removeAll()
                origin.x = 0
                row.append(view)
                origin.x += (viewSize.width + spacing)
            } else {
                row.append(view)
                origin.x += (viewSize.width + spacing)
            }
        }

        if !row.isEmpty {
            rows.append(row)
        }
        
        return rows
    }
}

import LinkPresentation
import UIKit
import SwiftUI

struct MainGroupLink: View {
    let url: URL
    @State var size: CGFloat = .zero
    @State var size2: CGFloat = .zero
    @State var meta: LPLinkMetadata? = nil
    @EnvironmentObject var popRoot: PopToRoot
    
    var body: some View {
        VStack {
            GroupPreviewView(url: url, width: $size, height: $size2, meta: $popRoot.cachedMetadata[url])
                .frame(width: size, height: size2, alignment: .leading)
                .aspectRatio(contentMode: .fill)
                .clipShape(Rectangle())
                .onChange(of: meta) { _, _ in
                    if let metaD = meta, popRoot.cachedMetadata[url] == nil {
                        popRoot.cachedMetadata[url] = metaD
                    }
                }
            
        }
    }
}

struct smallLink: View {
    let url: URL
    @State var size: CGFloat = .zero
    @State var size2: CGFloat = .zero
    @State var meta: LPLinkMetadata? = nil
    @EnvironmentObject var popRoot: PopToRoot
    
    var body: some View {
        VStack {
            GroupPreviewView(url: url, width: $size, height: $size2, meta: $popRoot.cachedMetadata[url])
                .frame(maxHeight: 100)
                .aspectRatio(contentMode: .fill)
                .clipShape(Rectangle())
                .onChange(of: meta) { _, _ in
                    if let metaD = meta, popRoot.cachedMetadata[url] == nil {
                        popRoot.cachedMetadata[url] = metaD
                    }
                }
            
        }
    }
}

struct GroupPreviewView: UIViewRepresentable {
    let url: URL
    @Binding var width: CGFloat
    @Binding var height: CGFloat
    @Binding var meta: LPLinkMetadata?
    
    func makeUIView(context: Context) -> UIView {
        let linkView = CustomLinkView()
        
        if let metaD = meta {
            DispatchQueue.main.async {
                linkView.metadata = metaD
                linkView.layer.cornerRadius = 0
                linkView.clipsToBounds = true
                
                let w1 = widthOrHeight(width: true) * 0.43
                let h1 = widthOrHeight(width: true) * 0.4
                self.width = w1
                self.height = h1
            }
        } else {
            let provider = LPMetadataProvider()
            provider.startFetchingMetadata(for: url) { metaData, error in
                guard let data = metaData, error == nil else { return }
                DispatchQueue.main.async {
                    linkView.metadata = data
                    linkView.layer.cornerRadius = 0
                    linkView.clipsToBounds = true
                    meta = data
               
                    let w1 = widthOrHeight(width: true) * 0.43
                    let h1 = widthOrHeight(width: true) * 0.4
                    self.width = w1
                    self.height = h1
                }
            }
        }
        return linkView
    }
    func updateUIView(_ uiView: UIView, context: Context) { }
}

struct MainPreviewLink: View {
    let url: URL
    let message: Bool
    @State var size: CGFloat = .zero
    @State var size2: CGFloat = .zero
    @State var meta: LPLinkMetadata? = nil
    @EnvironmentObject var popRoot: PopToRoot
    
    var body: some View {
        VStack {
            LinkPreviewView(url: url, width: $size, height: $size2, message: message, meta: $popRoot.cachedMetadata[url])
                .frame(width: size, height: size2, alignment: .leading)
                .aspectRatio(contentMode: .fill)
                .cornerRadius(15)
                .onChange(of: meta) { _, _ in
                    if let metaD = meta, popRoot.cachedMetadata[url] == nil {
                        popRoot.cachedMetadata[url] = metaD
                    }
                }
            
        }
    }
}

struct contextMenuLinkPreview: View {
    let url: URL
    @State var size: CGFloat = .zero
    @State var size2: CGFloat = .zero
    @State var meta: LPLinkMetadata? = nil
    
    var body: some View {
        LinkPreviewView(url: url, width: $size, height: $size2, message: false, meta: $meta)
            .frame(width: size, height: size2, alignment: .leading)
            .aspectRatio(contentMode: .fill)
            .cornerRadius(15)
    }
}

struct LinkPreviewView: UIViewRepresentable {
    let url: URL
    @Binding var width: CGFloat
    @Binding var height: CGFloat
    let message: Bool
    @Binding var meta: LPLinkMetadata?
    
    func makeUIView(context: Context) -> UIView {
        let linkView = CustomLinkView()
        
        if let metaD = meta {
            DispatchQueue.main.async {
                linkView.metadata = metaD
                let linksize = linkView.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
                let width = linksize.width
                let height = linksize.height
                
                if message {
                    let goal = widthOrHeight(width: true) * 0.8
                    if width > goal { self.width = goal
                    } else { self.width = width }
                    if height > 400 { self.height = 400
                    } else { self.height = height }
                } else {
                    let goal = widthOrHeight(width: true) * 0.7
                    if width > goal { self.width = goal
                    } else { self.width = width }
                    if height > 200 { self.height = 200
                    } else { self.height = height }
                }
            }
        } else {
            let provider = LPMetadataProvider()
            provider.startFetchingMetadata(for: url) { metaData, error in
                guard let data = metaData, error == nil else { return }
                DispatchQueue.main.async {
                    linkView.metadata = data
                    meta = data
                    let linksize = linkView.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
                    let width = linksize.width
                    let height = linksize.height
                    
                    if message {
                        let goal = widthOrHeight(width: true) * 0.8
                        if width > goal { self.width = goal
                        } else { self.width = width }
                        if height > 400 { self.height = 400
                        } else { self.height = height }
                    } else {
                        let goal = widthOrHeight(width: true) * 0.7
                        if width > goal { self.width = goal
                        } else { self.width = width }
                        if height > 200 { self.height = 200
                        } else { self.height = height }
                    }
                }
            }
        }

        return linkView
    }

    func updateUIView(_ uiView: UIView, context: Context) { }
}

class CustomLinkView: LPLinkView {
    
    init() {
        super.init(frame: .zero)
    }
        
    override var intrinsicContentSize: CGSize {
        return CGSize(width: frame.width, height: frame.height)
    }
}

func checkForFirstUrl(text: String) -> URL? {
    let types: NSTextCheckingResult.CheckingType = .link

    do {
        let detector = try NSDataDetector(types: types.rawValue)
        let matches = detector.matches(in: text, options: .reportCompletion, range: NSMakeRange(0, text.count))
        if let firstMatch = matches.first {
            return firstMatch.url
        }
    } catch {
        print("")
    }

    return nil
}

func getAllUrl(text: String) -> [URL]? {
    let types: NSTextCheckingResult.CheckingType = .link

    do {
        let detector = try NSDataDetector(types: types.rawValue)
        let matches = detector.matches(in: text, options: .reportCompletion, range: NSMakeRange(0, text.count))
        
        var final = [URL]()
        matches.forEach { item in
            if let link = item.url {
                final.append(link)
            }
        }
        return final
    } catch {
        print("")
    }

    return nil
}

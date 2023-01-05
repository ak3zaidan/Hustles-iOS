import SwiftUI
import Combine

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct OffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    @ViewBuilder
    func offsetX(completion: @escaping (CGFloat) -> ()) -> some View {
        self
            .overlay {
                GeometryReader {
                    let minX = $0.frame(in: .scrollView(axis: .horizontal)).minX
                    
                    Color.clear
                        .preference(key: OffsetKey.self, value: minX)
                        .onPreferenceChange(OffsetKey.self, perform: completion)
                }
            }
    }
    @ViewBuilder
    func tabMask(_ tabProgress: CGFloat, tabCount: Int) -> some View {
        ZStack {
            self
                .foregroundStyle(.gray)
            
            self
                .symbolVariant(.fill)
                .mask {
                    GeometryReader {
                        let size = $0.size
                        let capusleWidth = size.width / CGFloat(tabCount)
                        
                        Capsule()
                            .frame(width: capusleWidth)
                            .offset(x: tabProgress * (size.width - capusleWidth))
                    }
                }
        }
    }
}

struct ChildSizeReader<Content: View>: View {
  @Binding var size: CGSize

  let content: () -> Content
  var body: some View {
    ZStack {
      content().background(
        GeometryReader { proxy in
          Color.clear.preference(
            key: SizePreferenceKey.self,
            value: proxy.size
          )
        }
      )
    }
    .onPreferenceChange(SizePreferenceKey.self) { preferences in
      self.size = preferences
    }
  }
}

struct SizePreferenceKey: PreferenceKey {
  typealias Value = CGSize
  static var defaultValue: Value = .zero

  static func reduce(value _: inout Value, nextValue: () -> Value) {
    _ = nextValue()
  }
}

func widthOrHeight(width: Bool) -> CGFloat {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    let window = windowScene?.windows.first
    
    if width {
        return window?.screen.bounds.width ?? 0
    } else {
        return window?.screen.bounds.height ?? 0
    }
}

func setMaxBrightness() -> CGFloat {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    let window = windowScene?.windows.first
    let original = window?.screen.brightness
    window?.screen.brightness = 1.0
    return original ?? 0.5
}

func resetBrightness(reset: Double) {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    let window = windowScene?.windows.first
    window?.screen.brightness = reset
}

func top_Inset() -> CGFloat {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    let window = windowScene?.windows.first
    
    return window?.safeAreaInsets.top ?? 0
}

func bottom_Inset() -> CGFloat {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    let window = windowScene?.windows.first
    
    return window?.safeAreaInsets.bottom ?? 0
}

func calculateCosineSimilarity(_ paragraph1: String, _ paragraph2: String) -> Double {
    let words1 = paragraph1.lowercased().components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    let words2 = paragraph2.lowercased().components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    
    let allWords = Set(words1 + words2)
    
    var freqDict1: [String: Int] = [:]
    var freqDict2: [String: Int] = [:]
    
    for word in words1 {
        freqDict1[word, default: 0] += 1
    }
    
    for word in words2 {
        freqDict2[word, default: 0] += 1
    }
    
    let vector1 = allWords.map { Double(freqDict1[$0] ?? 0) }
    let vector2 = allWords.map { Double(freqDict2[$0] ?? 0) }
    
    var dotProduct = 0.0
    for i in 0..<allWords.count {
        dotProduct += vector1[i] * vector2[i]
    }
    
    let magnitude1 = sqrt(vector1.map { $0 * $0 }.reduce(0, +))
    let magnitude2 = sqrt(vector2.map { $0 * $0 }.reduce(0, +))

    let cosineSimilarity = dotProduct / (magnitude1 * magnitude2)
    
    return cosineSimilarity
}

extension View{
    @ViewBuilder
    func offsetY(completion: @escaping (CGFloat,CGFloat)->())->some View{
        self.modifier(OffsetHelper(onChange: completion))
    }
    func safeArea()->UIEdgeInsets{
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else{return .zero}
        guard let safeArea = scene.windows.first?.safeAreaInsets else{return .zero}
        return safeArea
    }
}
struct OffsetHelper: ViewModifier{
    var onChange: (CGFloat,CGFloat)->()
    @State var currentOffset: CGFloat = 0
    @State var previousOffset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader{proxy in
                    let minY = proxy.frame(in: .named("SCROLL")).minY
                    Color.clear
                        .preference(key: OffsetKeyNew.self, value: minY)
                        .onPreferenceChange(OffsetKeyNew.self) { value in
                            previousOffset = currentOffset
                            currentOffset = value
                            onChange(previousOffset,currentOffset)
                        }
                }
            }
    }
}
struct OffsetKeyNew: PreferenceKey{
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
struct HeaderBoundsKey: PreferenceKey{
    static var defaultValue: Anchor<CGRect>?
    
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue()
    }
}
enum SwipeDirection{
    case up
    case down
    case none
}

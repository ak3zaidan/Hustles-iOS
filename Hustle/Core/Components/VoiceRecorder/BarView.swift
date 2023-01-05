import SwiftUI

struct BarView: View {
    let isRecording: Bool
    var value: CGFloat = 0
    var sample: SampleModel?
    
    var body: some View {
        RoundedRectangle(cornerRadius: 25)
            .foregroundStyle(isRecording ? .purple : .white)
            .frame(width: 2, height: isRecording ? value : normalizeSoundLevel(level: sample?.sample ?? 0))
    }
    
    private func normalizeSoundLevel(level: Float) -> CGFloat {
        var level = max(2.0, CGFloat(level) + 40)
        if level > 2.0 {
            level *= 1.2
        }
        return level
    }
}

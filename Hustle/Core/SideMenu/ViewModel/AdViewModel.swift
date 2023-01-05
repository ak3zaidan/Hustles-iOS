import Foundation

enum AdViewModel: Int, CaseIterable{
    case normal
    case plus
    
    var title: String {
        switch self {
            case .normal: return "Reach"
            case .plus: return "Reach Plus"
        }
    }
}

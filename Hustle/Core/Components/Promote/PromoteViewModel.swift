import Foundation

enum PromoteViewModel: Int, CaseIterable{
    case USD
    case ELO
    
    var title: String {
        switch self {
            case .USD: return "Promote USD"
            case .ELO: return "Promote ElO"
        }
    }
}


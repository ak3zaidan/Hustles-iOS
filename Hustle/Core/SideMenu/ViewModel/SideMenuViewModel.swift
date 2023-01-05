import Foundation

enum SideMenuViewModel: Int, CaseIterable{
    case Account
    case help
    case privacy
    case Advertising
    case howTo
    case logout
    
    var description: String{
        switch self {
            case .Account: return "Account"
            case .help: return "Help"
            case .privacy: return "Privacy Policy and Terms"
            case .Advertising: return "Advertising"
            case .howTo: return "How To"
            case .logout: return "Logout"
        }
    }
    
    var imageName: String{
        switch self {
            case .Account: return "lock"
            case .help: return "questionmark.circle"
            case .privacy: return "hand.raised.app"
            case .Advertising: return "dollarsign.arrow.circlepath"
            case .howTo: return "questionmark"
            case .logout: return "arrow.left.square"
        }
    }
}

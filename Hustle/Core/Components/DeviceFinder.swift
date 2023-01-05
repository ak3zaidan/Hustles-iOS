import UIKit

public extension UIDevice {

    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        func mapToDevice(identifier: String) -> String {
            #if os(iOS)
            switch identifier {
            case "iPhone10,1", "iPhone10,4":                      return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                      return "iPhone 8 Plus"
            case "iPhone8,4":                                     return "iPhone SE"
            case "iPhone12,8":                                    return "iPhone SE"
            case "iPhone14,6":                                    return "iPhone SE"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":      return "iPad"
            case "iPad3,1", "iPad3,2", "iPad3,3":                 return "iPad"
            case "iPad3,4", "iPad3,5", "iPad3,6":                 return "iPad"
            case "iPad6,11", "iPad6,12":                          return "iPad"
            case "iPad7,5", "iPad7,6":                            return "iPad"
            case "iPad7,11", "iPad7,12":                          return "iPad"
            case "iPad11,6", "iPad11,7":                          return "iPad"
            case "iPad12,1", "iPad12,2":                          return "iPad"
            case "iPad13,18", "iPad13,19":                        return "iPad"
            case "iPad4,1", "iPad4,2", "iPad4,3":                 return "iPad"
            case "iPad5,3", "iPad5,4":                            return "iPad"
            case "iPad11,3", "iPad11,4":                          return "iPad"
            case "iPad13,1", "iPad13,2":                          return "iPad"
            case "iPad13,16", "iPad13,17":                        return "iPad"
            case "iPad2,5", "iPad2,6", "iPad2,7":                 return "iPad"
            case "iPad4,4", "iPad4,5", "iPad4,6":                 return "iPad"
            case "iPad4,7", "iPad4,8", "iPad4,9":                 return "iPad"
            case "iPad5,1", "iPad5,2":                            return "iPad"
            case "iPad11,1", "iPad11,2":                          return "iPad"
            case "iPad14,1", "iPad14,2":                          return "iPad"
            case "iPad6,3", "iPad6,4":                            return "iPad"
            case "iPad7,3", "iPad7,4":                            return "iPad"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":      return "iPad"
            case "iPad8,9", "iPad8,10":                           return "iPad"
            case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7":  return "iPad"
            case "iPad14,3", "iPad14,4":                          return "iPad"
            case "iPad6,7", "iPad6,8":                            return "iPad"
            case "iPad7,1", "iPad7,2":                            return "iPad"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":      return "iPad"
            case "iPad8,11", "iPad8,12":                          return "iPad"
            case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11":return "iPad"
            case "iPad14,5", "iPad14,6":                          return "iPad"
            case "i386", "x86_64", "arm64":                       return "\(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? ""))"
            default:                                              return ""
            }
            #endif
        }
        return mapToDevice(identifier: identifier)
    }()
}

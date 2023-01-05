import SwiftUI
import Firebase
import CryptoKit
import LocalAuthentication
import AuthenticationServices

class AuthViewModel: ObservableObject {
    private let service = UserService()
    private var tempUserSession: FirebaseAuth.User?
    @Published var userSession: FirebaseAuth.User?
    @Published var didAuthUser = false
    @Published var currentUser: User?
    @Published var signInError: String = ""
    @Published var resetError: String = ""
    @Published var registerError: String = ""
    var verifierUserNames: [String] = []
    
    init(){
        self.userSession = Auth.auth().currentUser
        self.fetchUser { }
    }
    
    func login(withEmail email: String, password: String){
        if !email.isEmpty && !password.isEmpty {
            Auth.auth().signIn(withEmail: email, password: password){ result, error in
                if let error = error {
                    if error.localizedDescription.contains("The email address is badly formatted") {
                        self.signInError = "The email address is badly formatted"
                    } else if error.localizedDescription.contains("password is invalid") {
                        self.signInError = "incorrect password or email"
                    } else if error.localizedDescription.contains("no user record corresponding") {
                        self.signInError = "We could not find your account"
                    } else {
                        self.signInError = "An error occured"
                    }
                    return
                }
                guard let user = result?.user else {
                    self.signInError = "An error occured"
                    return
                }
                self.userSession = user
                self.fetchUser { }
            }
        } else {
            self.signInError = "incorrect password or email"
        }
    }
    func register(withEmail email: String, password: String, fullname: String, username: String, country: String, completion: @escaping(Bool) -> Void){
        
        Auth.auth().createUser(withEmail: email, password: password){ result, error in
            if let error = error {
                if error.localizedDescription.contains("email address is already in use") {
                    self.registerError = "email address is already in use"
                } else {
                    self.registerError = "An error occured, try again later"
                }
                completion(false)
                return
            }
            
            guard let user = result?.user else {
                self.registerError = "An error occured, try again later"
                completion(false)
                return
            }
            self.tempUserSession = user
            
            let arr = [String]()
            
            let privateKey = Curve25519.KeyAgreement.PrivateKey()
            let privateKeyData = privateKey.rawRepresentation
            let privateKeyBase64 = privateKeyData.base64EncodedString()
            
            let publicKey = privateKey.publicKey
            let publicKeyData = publicKey.rawRepresentation
            let publicKeyBase64 = publicKeyData.base64EncodedString()
            
            let data = ["email": email,
                        "username": username.lowercased(),
                        "fullname": fullname,
                        "uid": user.uid,
                        "zipCode": "",
                        "following": arr,
                        "verifiedTips": 0,
                        "badges": arr,
                        "likedHustles": arr,
                        "jobPointer": arr,
                        "pinnedGroups": arr,
                        "alertsShown": "",
                        "elo": 550,
                        "shopPointer": arr,
                        "followers": 0,
                        "userCountry": country,
                        "myMessages": arr,
                        "publicKey": publicKeyBase64,
                        "timestamp": Timestamp(date: Date()),
                        "lastSeen": Timestamp(date: Date()),
                        "completedjobs": 0] as [String : Any]
            
            Firestore.firestore().collection("users")
                .document(user.uid)
                .setData(data){ error in
                    if error != nil {
                        self.service.verifyUser(withUid: user.uid) { bool in
                            if bool {
                                completion(true)
                                self.registerHelper()
                                self.save(userUID: user.uid, privatekey: privateKeyBase64)
                            } else {
                                Firestore.firestore().collection("users").document(user.uid)
                                    .setData(data){ error in
                                        if error != nil {
                                            completion(false)
                                            self.registerError = "An error occured, try again later"
                                        } else {
                                            completion(true)
                                            self.registerHelper()
                                            self.save(userUID: user.uid, privatekey: privateKeyBase64)
                                        }
                                    }
                                
                            }
                        }
                    } else {
                        completion(true)
                        self.registerHelper()
                        self.save(userUID: user.uid, privatekey: privateKeyBase64)
                    }
                }
            
        }
    }
    func registerHelper(){
        self.didAuthUser = true
        self.userSession = self.tempUserSession
        self.fetchUser { }
    }
    func signOut(){
        currentUser = nil
        self.didAuthUser = false
        userSession = nil
        try? Auth.auth().signOut()
    }
    func fetchUser(completion: @escaping() -> Void){
        guard let uid = self.userSession?.uid else { return }
        service.fetchUserWithRedo(withUid: uid) { user in
            self.currentUser = user
            completion()
        }
    }
    func resetPassword(email: String, completion: @escaping(Bool) -> Void){
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                if error.localizedDescription.contains("The email address is badly formatted") {
                    self.resetError = "The email address is badly formatted"
                } else if error.localizedDescription.contains("no user record corresponding") {
                    self.resetError = "We could not find your account"
                } else {
                    self.resetError = "An error occured, try again later"
                }
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    func checkUserNameInUse(username: String, completion: @escaping(Bool) -> Void){
        if verifierUserNames.contains(username){
            completion(true)
        } else {
            Firestore.firestore().collection("users")
                .whereField("username", isEqualTo: username.lowercased()).limit(to: 1)
                .getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }
                    if documents.isEmpty {
                        self.verifierUserNames.append(username.lowercased())
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            
        }
    }
    func save(userUID: String, privatekey: String) {
        let passwordData = privatekey.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrSynchronizable as String: kCFBooleanTrue!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecAttrService as String: "hustles/\(userUID)",
            kSecAttrAccount as String: userUID,
            kSecValueData as String: passwordData
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
}

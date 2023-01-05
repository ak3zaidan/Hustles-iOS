import Foundation
import UIKit
import Firebase
import FirebaseFirestore

class QuestionModel: ObservableObject{
    @Published var new = [Question]()
    @Published var top = [Question]()
    @Published var goodAnswers = [(String, String)]()
    @Published var votedUpAnswers = [(String, String)]()
    @Published var votedDownAnswers = [(String, String)]()
    @Published var upVotes = [String]()
    @Published var downVotes = [String]()
    
    @Published var allQuestions: [(String, [Answer])] = []
    
    @Published var didUploadShop = false
    @Published var uploadError: String = ""
    
    @Published var firstNew: Timestamp?
    @Published var lastNew: Timestamp?
    @Published var lastTop: Int?
    
    @Published var gettingData = false
    let service = QuestionService()
    
    func tagUserQuestion(myUsername: String, otherUsername: String, message: String, questionID: String?) {
        ExploreService().sendNotification(type: "Question", taggerUsername: myUsername, taggedUsername: otherUsername, taggedUID: nil, caption: message, tweetID: nil, groupName: nil, newsName: nil, questionID: questionID, taggerUID: nil)
    }
    func getAnswers(questionID: String?, refresh: Bool, count: Int){
        if let id = questionID {
            if let x = allQuestions.firstIndex(where: { $0.0 == id }) {
                if allQuestions[x].1.isEmpty || refresh {
                    service.getAnswers(questionID: id) { answers in
                        self.allQuestions[x].1 = answers
                    }
                }
            } else if count > 0 {
                service.getAnswers(questionID: id) { answers in
                    let new = (id, answers)
                    self.allQuestions.append(new)
                }
            } else if !allQuestions.contains(where: { $0.0 == id }){
                let new = (id, [Answer]())
                self.allQuestions.append(new)
            }
        }
    }
    func getAnswersForImageQ(questionID: String?, refresh: Bool){
        if let id = questionID {
            if let x = allQuestions.firstIndex(where: { $0.0 == id }) {
                if refresh {
                    service.getAnswers(questionID: id) { answers in
                        self.allQuestions[x].1 = answers
                    }
                }
            } else {
                service.getAnswers(questionID: id) { answers in
                    let new = (id, answers)
                    self.allQuestions.append(new)
                }
            }
        }
    }
    func refresh(){
        if let first = firstNew {
            service.refreshNew(last: first) { questions in
                var temp = questions
                temp.removeAll { element in
                    return self.new.contains(element)
                }
                for i in 0..<temp.count {
                    temp[i].tags = temp[i].tagJoined?.split(separator: ",").map { String($0) }
                }
                if !temp.isEmpty {
                    self.firstNew = temp.first?.timestamp
                }
                if self.new.isEmpty {
                    self.lastNew = temp.last?.timestamp
                }
                self.new.insert(contentsOf: self.sortArrayWithPromotionPriority(array: temp), at: 0)
            }
        }
    }
    func getNew(){
        service.getNew(last: lastNew) { questions in
            if !questions.isEmpty {
                var temp = questions
                for i in 0..<temp.count {
                    temp[i].tags = temp[i].tagJoined?.split(separator: ",").map { String($0) }
                }
                self.firstNew = questions.first?.timestamp
                self.lastNew = questions.last?.timestamp
                self.new += self.sortArrayWithPromotionPriority(array: temp)
            }
        }
    }
    func getTop(){
        if !gettingData {
            gettingData = true
            service.getTop(last: lastTop) { questions in
                self.gettingData = false
                if !questions.isEmpty {
                    var temp = questions
                    for i in 0..<temp.count {
                        temp[i].tags = temp[i].tagJoined?.split(separator: ",").map { String($0) }
                    }
                    self.lastTop = questions.last?.votes
                    self.top += self.sortArrayWithPromotionPriority(array: temp)
                }
            }
        }
    }
    func deleteQuestion(id: String?, count: Int, image1: String?, image2: String?){
        service.deleteQuestion(questionID: id, answersCount: count)
        if let image = image1 {
            ImageUploader.deleteImage(fileLocation: image) { _ in }
        }
        if let image = image2 {
            ImageUploader.deleteImage(fileLocation: image) { _ in }
        }
    }
    func deleteAnswer(id: String?, id2: String?, image: String?){
        service.deleteAnswer(questionID: id, answerID: id2)
        if let photo = image {
            ImageUploader.deleteImage(fileLocation: photo) { _ in }
        }
    }
    func voteQuestion(id: String?, val: Int){
        service.voteQuestion(questionID: id, value: val)
    }
    func voteAnswer(id: String?, id2: String?, value: Int){
        service.voteAnswer(questionID: id, answerID: id2, value: value)
    }
    func acceptAnswer(id: String?, id2: String?){
        service.acceptAnswer(questionID: id, answerID: id2)
    }
    func uploadQuestion(title: String, caption: String, tags: [String], promoted: Int, username: String, profilePhoto: String?){
        service.uploadQuestion(title: title, caption: caption, tags: tags, promoted: promoted, username: username, profilePhoto: profilePhoto) { success in
            if success {
                self.didUploadShop = true
            } else {
                self.uploadError = "Could not Upload at this time"
            }
        }
    }
    func uploadQuestionImage(caption: String, promoted: Int, username: String, profilePhoto: String?, image1: UIImage?, image2: UIImage?){
        if let photo1 = image1 {
            ImageUploader.uploadImage(image: photo1, location: "questions", compression: 0.25) { loc, _ in
                if loc.isEmpty {
                    self.uploadError = "Could not Upload at this time"
                } else if let photo2 = image2  {
                    ImageUploader.uploadImage(image: photo2, location: "questions", compression: 0.25) { locSec, _ in
                        self.service.uploadQuestionImage(caption: caption, promoted: promoted, username: username, profilePhoto: profilePhoto, image1: loc, image2: locSec.isEmpty ? nil : locSec) { success in
                            if success {
                                self.didUploadShop = true
                            } else {
                                self.uploadError = "Could not Upload at this time"
                            }
                        }
                    }
                } else {
                    self.service.uploadQuestionImage(caption: caption, promoted: promoted, username: username, profilePhoto: profilePhoto, image1: loc, image2: nil) { success in
                        if success {
                            self.didUploadShop = true
                        } else {
                            self.uploadError = "Could not Upload at this time"
                        }
                    }
                }
            }
        }
    }
    func uploadAnswer(questionID: String?, caption: String, username: String, profilePhoto: String?){
        service.uploadAnswer(questionID: questionID, caption: caption, username: username, profilePhoto: profilePhoto)
    }
    func uploadAnswerImage(image: UIImage?, questionID: String?, caption: String, username: String, profilePhoto: String?, completion: @escaping(String) -> Void){
        if let id = questionID {
            if let photo = image {
                ImageUploader.uploadImage(image: photo, location: "questions", compression: 0.25) { loc, _ in
                    self.service.uploadAnswerImage(questionID: id, caption: caption, username: username, profilePhoto: profilePhoto, image: loc)
                    completion(loc)
                }
            } else {
                completion("")
                self.service.uploadAnswerImage(questionID: id, caption: caption, username: username, profilePhoto: profilePhoto, image: nil)
            }
        }
    }
    func sortArrayWithPromotionPriority(array: [Question]) -> [Question] {
        let currentDate = Date()
        var promotedArray: [Question] = []
        var nonPromotedArray: [Question] = []
        for question in array {
            if question.promoted?.dateValue() ?? currentDate > currentDate {
                promotedArray.append(question)
            } else {
                nonPromotedArray.append(question)
            }
        }
        return promotedArray + nonPromotedArray
    }
}

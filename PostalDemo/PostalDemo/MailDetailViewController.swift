//
//  MailDetailViewController.swift
//  PostalDemo
//
//  Created by Christian Finker on 30.04.19.
//  Copyright © 2019 Snips. All rights reserved.
//

import UIKit
import Postal
import Result

class MailDetailViewController: UIViewController {
    var message: FetchResult? = nil;
    var postal: Postal? = nil;
    var keychain = KeychainSwift()
    var classiferName = "";
    var selectedSender = "";
    
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var bodyTextView: UITextView!
    
    @IBOutlet weak var spamCoreML: BadgeSwift!
    @IBOutlet weak var authorCoreML: BadgeSwift!
    @IBOutlet weak var spamUClassify: BadgeSwift!
    @IBOutlet weak var authorUClassify: BadgeSwift!
    @IBOutlet weak var genderUClassify: BadgeSwift!
    @IBOutlet weak var moodUClassify: BadgeSwift!
    @IBOutlet weak var languageUClassify: BadgeSwift!
    @IBAction func TrainMLButton(_ sender: Any) {
        sendTrainAuthorClassRequest()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.classiferName = keychain.get("mailEmail") ?? "noMailClassifer";
        self.classiferName = self.classiferName.replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: [.regularExpression, .caseInsensitive]) + "hil"
        
        guard message != nil else { return }
        
        var fromMailAddresses = "";
        for fromItem in message?.header?.from  ?? []{
            fromMailAddresses += fromItem.displayName
        }
        fromLabel.text = fromMailAddresses;
        self.selectedSender = fromMailAddresses.replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: [.regularExpression, .caseInsensitive])
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "dd.MM.YYYY HH:mm:ss"
        dateLabel.text = dateFormatterPrint.string(from: message?.header?.receivedDate ?? Date())
                
        message?.body?.allParts.forEach({ (part) in
            postal?.fetchAttachments("INBOX", uid: message?.uid ?? 0, partId: part.id, onAttachment: { (mailData) in
                if !mailData.rawData.isEmpty {
                    let decodedData = mailData.decodedData
                    let attachmentStr = String(data: decodedData, encoding: .utf8)
                    self.bodyTextView.text = attachmentStr ?? "no content"
                }
            }, onComplete: { error in
                if let error = error {
                    print("Fail to receive message attachment with error = \(error.localizedDescription)")
                } else {
                    print("Fetch attachment successed!")
                }
                self.authorUClassify.text = "\(self.getClassifyAuthorInformation(bodyText: self.bodyTextView.text))"
                 self.authorCoreML.text = "\(self.getCoreMLPredictionAuthorship(bodyText: self.bodyTextView.text))"
                self.spamCoreML.text = "\(self.getCoreMLPrediction(bodyText: self.bodyTextView.text))"
                self.spamUClassify.text = "\(self.getClassifyInformationRequest(bodyText: self.bodyTextView.text, classifierName: "MailSpamClassifier", user: "webrabbit"))"
                self.languageUClassify.text = "\(self.getClassifyInformationRequest(bodyText: self.bodyTextView.text, classifierName: "language-detector", user: "uclassify"))"
                self.moodUClassify.text = "\(self.getClassifyInformationRequest(bodyText: self.bodyTextView.text, classifierName: "sentiment", user: "uclassify"))"
                self.genderUClassify.text = "\(self.getClassifyInformationRequest(bodyText: self.bodyTextView.text, classifierName: "genderanalyzer_v5", user: "uclassify"))"
            })
        })
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            switch (segue.identifier, segue.destination) {
            case (.some("authorNOKSegue"), let vc as TrainSingleMailTableViewController):
                vc.mailBodyText = self.bodyTextView.text
                break;
            default: break
            }
        }
    
    func getCoreMLPrediction(bodyText: String) -> String {
        let model = MailSpamClassifier()
        guard let mailSpamClassifierOutput = try? model.prediction(text: bodyText) else {
            fatalError("Unexpected runtime error.")
        }
        return " \(mailSpamClassifierOutput.label)"
    }
    
    func getCoreMLPredictionAuthorship(bodyText: String) -> String {
        let w2v = Words2Vector()
        let label = ModelUpdater.predictLabelFor(w2v.createSelectedFeaturesVector(text: bodyText))
        print("Author coreml: \(label!)")
        return label ?? "no data"
    }
    
    func getClassifyAuthorInformation(bodyText: String) -> String {
        return self.getClassifyInformationRequest(bodyText: bodyText, classifierName: self.classiferName, user: "webrabbit")
        }
    
    func getClassifyInformationRequest(bodyText: String, classifierName: String, user: String) -> String {
        // prepare json data
        let json: [String: Any] = ["texts":[bodyText]]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create get request
        let url = URL(string: "https://api.uclassify.com/v1/" + user + "/" + classifierName + "/classify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Token W2tWoQIpqK0P", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        var result = "";
        var lastPValue = 0.0;
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                //print(error?.localizedDescription ?? "No data")
                return
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                guard let jsonArray = jsonResponse as? [[String: Any]] else {
                    return
                }
                
                //print(jsonArray)
                for item in jsonArray {
                    for innerItem in (item["classification"] as? [[String: Any]])! {
                        let pValue = innerItem["p"] as? Double ?? 0.0
                        if(pValue > lastPValue) {
                            lastPValue = pValue
                            result = innerItem["className"] as? String ?? "no class"
                            result += " ( \(pValue) )"
                            result += "\n"
                        }
                    }
                }
                
            } catch let parsingError {
                print("Error", parsingError)
            }
            
            semaphore.signal()
        }
        task.resume()
        
        if semaphore.wait(timeout: .now() + 60) == .timedOut {
            self.showAlertError("Error while getting cassify data for " + classifierName, message: "Timeout Error, please try again later")
        }
        return result;
    }
    
    func sendTrainAuthorClassRequest() {
        self.sendTrainClassRequest(classifierName: self.classiferName, className: self.selectedSender)
    }
    
    @IBAction func sendTrainSpamClassRequest() {
        self.sendTrainClassRequest(classifierName: "MailSpamClassifier", className: "spam")
    }
    
    @IBAction func sendTrainHamClassRequest() {
        self.sendTrainClassRequest(classifierName: "MailSpamClassifier", className: "ham")
    }
    
    func sendTrainClassRequest(classifierName: String, className: String) {
        // prepare json data
        let json: [String: Any] = ["texts": [self.bodyTextView.text]]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let url = URL(string: "https://api.uclassify.com/v1/me/" + classifierName + "/" + className + "/train")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Token f6HQtYfYlzUx", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // insert json data to the request
        request.httpBody = jsonData
        
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
            semaphore.signal()
        }
        task.resume()
        
        if semaphore.wait(timeout: .now() + 15) == .timedOut {
            self.showAlertError("Error while training class", message: "Timeout Error, please try again later")
        }
    }
    
}

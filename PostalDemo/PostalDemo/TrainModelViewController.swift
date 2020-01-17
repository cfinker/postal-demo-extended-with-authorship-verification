//
//  TrainModelViewController.swift
//  PostalDemo
//
//  Created by Christian Finker on 30.06.19.
//  Copyright © 2019 Snips. All rights reserved.
//

import UIKit
import Postal
import Result
import CoreML

class TrainModelViewController: UITableViewController {
    
    var messages: [FetchResult] = []
    var senders: [String] = [];
    var existingClassifiers: [String] = [];
    var keychain = KeychainSwift()
    var classiferName = "";
    var postal: Postal? = nil;
    var featureProviders = [MLFeatureProvider]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.classiferName = keychain.get("mailEmail") ?? "noMailClassifer";
        self.classiferName = self.classiferName.replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: [.regularExpression, .caseInsensitive]) + "hil"

        sendCreateClassiferRequest()
        getClassiferInformation()
        
        for message in self.messages {
            if let sender = message.header?.from.description {
                if(!self.senders.contains(extractSenderName(sentence: sender))) {
                    self.senders.insert(extractSenderName(sentence: sender), at: 0)
                }
            }
        }
        
      //  self.senders = self.senders.filter { !self.existingClassifiers.contains($0.replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: [.regularExpression, .caseInsensitive])) }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return senders.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "senderCell", for: indexPath)
        
        cell.textLabel?.text = senders[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sv = UIViewController.displaySpinner(onView: self.view);
        DispatchQueue.global().async {
            var selectedSender = self.senders[indexPath.row];
            
            selectedSender = selectedSender.replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: [.regularExpression, .caseInsensitive])
            
            self.sendCreateNewClassRequest(selectedSender: selectedSender)

            for message in self.messages {
                if let sender = message.header?.from.description {
                    var currentSender = self.extractSenderName(sentence: sender)
                    currentSender = currentSender.replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: [.regularExpression, .caseInsensitive])
                    if selectedSender == currentSender {
                        let mailBody = self.getBodyFromMail(message: message)
                       // self.sendTrainClassRequest(selectedSender: selectedSender, bodyText: mailBody)
                        self.createTaingDataForUpdatableKNN(text: mailBody, sender: selectedSender)
                    }
                }
            }
            ModelUpdater.updateWith(trainingData: MLArrayBatchProvider(array: self.featureProviders)) {
                UIViewController.removeSpinner(spinner: sv)
            }
        }
        
    }
    
    func createTaingDataForUpdatableKNN(text: String, sender: String) {
        let words2Vec = Words2Vector();
        let mLMultiArrayFeature = words2Vec.createSelectedFeaturesVector(text: text);
        
        self.featureProviders.append(UpdatableKNNTrainingInput(input: mLMultiArrayFeature, output: sender))
    }
    
    func sendCreateClassiferRequest() {
        // prepare json data
        let json: [String: Any] = ["classifierName": self.classiferName]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let url = URL(string: "https://api.uclassify.com/v1/me/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        guard let infoDictionary = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        guard let writeToken = infoDictionary["UCLASSIFY_WRITE_KEY"] as? String else {
            fatalError("UCLASSIFY_WRITE_KEY Key not set in plist for this environment")
        }
        request.addValue("Token " + writeToken, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error while creating classifer")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }
        task.resume()
    }
    
    func getClassiferInformation() {
        guard let infoDictionary = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        guard let readToken = infoDictionary["UCLASSIFY_READ_KEY"] as? String else {
            fatalError("UCLASSIFY_READ_KEY Key not set in plist for this environment")
        }
        guard let user = infoDictionary["UCLASSIFY_USER_API"] as? String else {
            fatalError("UCLASSIFY_USER_API Key not set in plist for this environment")
        }
               
        // create get request
        let url = URL(string: "https://api.uclassify.com/v1/" + user + "/" + self.classiferName)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
    
        request.addValue("Token " + readToken , forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                guard let jsonArray = jsonResponse as? [[String: Any]] else {
                    return
                }
                
                for item in jsonArray {
                    let title = item["className"] as? String
                    self.existingClassifiers.insert(title ?? "", at: 0)
                }
                
            } catch let parsingError {
                print("Error", parsingError)
            }
            
            semaphore.signal()
        }
        task.resume()
        
        if semaphore.wait(timeout: .now() + 15) == .timedOut {
            print("Error while creating new class")
           // self.showAlertError("Error while creating new class", message: "Timeout Error, please try again later")
        }
    }
    
    func sendCreateNewClassRequest(selectedSender: String) {
        // prepare json data
        let json: [String: Any] = ["className": selectedSender]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let url = URL(string: "https://api.uclassify.com/v1/me/" + self.classiferName + "/addClass")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        guard let infoDictionary = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        guard let writeToken = infoDictionary["UCLASSIFY_WRITE_KEY"] as? String else {
            fatalError("UCLASSIFY_WRITE_KEY Key not set in plist for this environment")
        }
        request.addValue("Token " + writeToken, forHTTPHeaderField: "Authorization")
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
            print("Error while creating new class")
            //self.showAlertError("Error while creating new class", message: "Timeout Error, please try again later")
        }
    }
    
    func getBodyFromMail(message: FetchResult) -> String {
        var bodyText = "";
        
        let semaphore = DispatchSemaphore(value: 0)
        message.body?.allParts.forEach({ (part) in
            postal?.fetchAttachments("INBOX", uid: message.uid , partId: part.id, onAttachment: { (mailData) in
                if !mailData.rawData.isEmpty {
                    let decodedData = mailData.decodedData
                    let attachmentStr = String(data: decodedData, encoding: .utf8)
                    bodyText = attachmentStr ?? "no content"
                    semaphore.signal()
                }
            }, onComplete: { error in
                if let error = error {
                    print(error.localizedDescription)
                    //self.showAlertError("Error while creating get mail body", message: "Fail to receive message attachment with error = \(error.localizedDescription)")
                } else {
                    print("Fetch attachment successed!")
                }
            })
        })
        
        if semaphore.wait(timeout: .now() + 30) == .timedOut {
            print("Error while getting mail body, timeout")
            //self.showAlertError("Error while getting mail body", message: "Timeout Error, please try again later")
        }
        
        return bodyText;
    }
    
    func sendTrainClassRequest(selectedSender: String, bodyText: String) {
        // prepare json data
        let json: [String: Any] = ["texts": [bodyText]]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let url = URL(string: "https://api.uclassify.com/v1/me/" + self.classiferName + "/" + selectedSender + "/train")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        guard let infoDictionary = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        guard let writeToken = infoDictionary["UCLASSIFY_WRITE_KEY"] as? String else {
            fatalError("UCLASSIFY_WRITE_KEY Key not set in plist for this environment")
        }
        request.addValue("Token " + writeToken, forHTTPHeaderField: "Authorization")
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
            print("Error while training class, timeout")
          //  self.showAlertError("Error while training class", message: "Timeout Error, please try again later")
        }
    }
    
    func extractSenderName(sentence: String) -> String {
        let pattern = "\"(.*?)\""
        let regex = try! NSRegularExpression(pattern: pattern)
        
        
        if let match = regex.firstMatch(in: sentence, range: NSRange(location: 0, length: sentence.utf16.count)) {
            return (sentence as NSString).substring(with: match.range(at: 1))
        }
        
        return ""
    }
}

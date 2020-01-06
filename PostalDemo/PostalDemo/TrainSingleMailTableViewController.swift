//
//  TrainSingleMailTableViewController.swift
//  PostalDemo
//
//  Created by Christian Finker on 20.09.19.
//  Copyright © 2019 Snips. All rights reserved.
//

import UIKit

class TrainSingleMailTableViewController: UITableViewController {
    
    
    var existingClassifiers: [String] = [];
    var keychain = KeychainSwift()
    var classiferName = "";
    var mailBodyText = "";
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.classiferName = keychain.get("mailEmail") ?? "noMailClassifer";
        self.classiferName = self.classiferName.replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: [.regularExpression, .caseInsensitive])
        
        getClassiferInformation()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return existingClassifiers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "senderCell", for: indexPath)
        
        cell.textLabel?.text = existingClassifiers[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sv = UIViewController.displaySpinner(onView: self.view);
        DispatchQueue.global().async {
            let selectedClass = self.existingClassifiers[indexPath.row];
            self.sendTrainClassRequest(selectedClass: selectedClass, bodyText: self.mailBodyText)
            UIViewController.removeSpinner(spinner: sv)
        }
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func getClassiferInformation() {
        // create get request
        let url = URL(string: "https://api.uclassify.com/v1/webrabbit/" + self.classiferName)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Token W2tWoQIpqK0P", forHTTPHeaderField: "Authorization")
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
            self.showAlertError("Error while creating new class", message: "Timeout Error, please try again later")
        }
    }
    
    func sendTrainClassRequest(selectedClass: String, bodyText: String) {
        // prepare json data
        let json: [String: Any] = ["texts": [bodyText]]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let url = URL(string: "https://api.uclassify.com/v1/me/" + self.classiferName + "/" + selectedClass + "/train")!
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

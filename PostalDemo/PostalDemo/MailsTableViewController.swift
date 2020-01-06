//
//  MailsTableViewController.swift
//  PostalDemo
//
//  Created by Kevin Lefevre on 06/06/2016.
//  Copyright © 2017 Snips. All rights reserved.
//

import UIKit
import Postal
import Result

class MailsTableViewController: UITableViewController {
    let keychain = KeychainSwift()
    var postal: Postal? = nil;
    fileprivate var messages: [FetchResult] = []
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.identifier, segue.destination) {
        case (.some("mailDetailSegue"), let vc as MailDetailViewController):
            if let indexPath = tableView.indexPathForSelectedRow{
                vc.message = self.messages[indexPath.item]
                vc.postal = self.postal;
            }
            break;
        case (.some("trainSegue"), let vc as TrainModelViewController):
            vc.messages = self.messages
            vc.postal = self.postal;
            break;
        default: break
        }
    }
}

// MARK: - View lifecycle

extension MailsTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let configuration = Configuration(hostname: keychain.get("mailHostname")! , port: UInt16(keychain.get("mailportText")!)!, login: keychain.get("mailEmail")!, password: .plain(keychain.get("mailPassword")!), connectionType: .tls, checkCertificateEnabled: true)
        
        let sv = UIViewController.displaySpinner(onView: self.view);
        DispatchQueue.global().async {
            let postal: Postal = Postal(configuration: configuration)
            self.postal = postal;
            // Do connection
            postal.connect(timeout: Postal.defaultTimeout, completion: { [weak self] result in
                switch result {
                case .success: // Fetch 510 last mails of the INBOX
                    postal.fetchLast("INBOX", last: 510, flags: [ .fullHeaders, .body, .internalDate, .size, .structure ], onMessage: { message in
                        self?.messages.insert(message, at: 0)
                        
                        }, onComplete: { error in
                            if let error = error {
                                self?.showAlertError("Fetch error", message: (error as NSError).localizedDescription)
                            } else {
                                UIViewController.removeSpinner(spinner: sv)
                                self?.tableView.reloadData()
                            }
                    })

                case .failure(let error):
                    print("error: \(error)")
                    self?.showAlertError("Connection error", message: (error as NSError).localizedDescription)
                }
            })
        }
    }
}

// MARK: - Table view data source

extension MailsTableViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MailTableViewCell", for: indexPath)

        let message = messages[indexPath.row]
        
        cell.textLabel?.text = message.header?.subject
        cell.detailTextLabel?.text = message.header?.from.description
        
        return cell
    }
}

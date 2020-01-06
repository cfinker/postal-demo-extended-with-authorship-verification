//
//  LoginTableViewController.swift
//  PostalDemo
//
//  Created by Kevin Lefevre on 24/05/2016.
//  Copyright © 2017 Snips. All rights reserved.
//

import UIKit
import Postal

enum LoginError: Error {
    case badEmail
    case badPassword
    case badHostname
    case badPort
}

extension LoginError: CustomStringConvertible {
    var description: String {
        switch self {
        case .badEmail: return "Bad mail"
        case .badPassword: return "Bad password"
        case .badHostname: return "Bad hostname"
        case .badPort: return "Bad port"
        }
    }
}

final class LoginTableViewController: UITableViewController {
    fileprivate let mailsSegueIdentifier = "mailsSegue"

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var hostnameTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    
    var provider: MailProvider?
    var preventKeychainOverride = false;
}

// MARK: - View lifecycle

extension LoginTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let provider = provider, let configuration = provider.preConfiguration {
            emailTextField.placeholder = "exemple@\(provider.hostname)"
            hostnameTextField.isUserInteractionEnabled = true
            hostnameTextField.text = configuration.hostname
            portTextField.isUserInteractionEnabled = true
            portTextField.text = "\(configuration.port)"
        }
        
        let keychain = KeychainSwift()
        if(keychain.get("mailPassword")?.count ?? 0 > 3) {
            self.preventKeychainOverride = true;
            //performSegue(withIdentifier: mailsSegueIdentifier, sender: self)
            hostnameTextField.text = keychain.get("mailHostname") ?? "";
            portTextField.text = keychain.get("mailportText") ?? "";
            emailTextField.text = keychain.get("mailEmail") ?? "";
            passwordTextField.text = keychain.get("mailPassword") ?? "";
        }
    }
}

// MARK: - Navigation management

extension LoginTableViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.identifier) {
        case (.some(mailsSegueIdentifier)):
            do {
                try createConfiguration()
            } catch let error as LoginError {
                showAlertError("Error login", message: (error as NSError).description)
            } catch {
                fatalError()
            }
            break
        default: break
        }
    }
}

// MARK: - Helpers

private extension LoginTableViewController {
    
    func createConfiguration() throws {
        if(self.preventKeychainOverride) {
          return
        }
        
        guard let email = emailTextField.text , !email.isEmpty else { throw LoginError.badEmail  }
        guard let password = passwordTextField.text , !password.isEmpty else { throw LoginError.badPassword }
        guard let hostname = hostnameTextField.text , !hostname.isEmpty else { throw LoginError.badHostname }
        guard let portText = portTextField.text , !portText.isEmpty else { throw LoginError.badPort }
        guard UInt16(portText) != nil else { throw LoginError.badPort }
        
        let keychain = KeychainSwift()
        keychain.set(hostname, forKey: "mailHostname")
        keychain.set(portText, forKey: "mailportText")
        keychain.set(email, forKey: "mailEmail")
        keychain.set(password, forKey: "mailPassword")
    }
}

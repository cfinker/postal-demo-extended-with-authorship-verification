//
//  ViewController.swift
//  PostalDemo
//
//  Created by Kevin Lefevre on 23/05/2016.
//  Copyright © 2017 snips. All rights reserved.
//

import UIKit
import Postal

enum MailProvider: Int {
    case icloud
    case google
    case yahoo
    case outlook
    case aol
    case other
    
    var hostname: String {
        switch self {
        case .icloud: return "icloud.com"
        case .google: return "gmail.com"
        case .yahoo: return "yahoo.com"
        case .outlook: return "outlook.com"
        case .aol: return "aol.com"
        case .other: return ""
        }
    }
    
    var preConfiguration: Configuration? {
        switch self {
        case .icloud: return .icloud(login: "", password: "")
        case .google: return .gmail(login: "", password: .plain(""))
        case .yahoo: return .yahoo(login: "", password: .plain(""))
        case .outlook: return .outlook(login: "", password: "")
        case .aol: return .aol(login: "", password: "")
        case .other:
           return Configuration.init(hostname: "", port: 143, login: "", password: .plain(""), connectionType: .tls, checkCertificateEnabled: true)
        }
    }
}

final class AddAccountTableViewController: UITableViewController {
    fileprivate let loginSegueIdentifier = "loginSegue"    
}

// MARK: - View lifecycle

extension AddAccountTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let keychain = KeychainSwift()
        if(keychain.get("mailPassword") != nil && keychain.get("mailPassword")?.count ?? 0 > 3) {
            performSegue(withIdentifier: loginSegueIdentifier, sender: MailProvider(rawValue: 1))
        }
    }
}


// MARK: - Navigation management

extension AddAccountTableViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.identifier, segue.destination, sender) {
        case (.some(loginSegueIdentifier), let vc as LoginTableViewController, let provider as Int):
            vc.provider = MailProvider(rawValue: provider)
        default: break
        }
    }
}

// MARK: - UITableViewDelegate

extension AddAccountTableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let provider = MailProvider(rawValue: (indexPath as NSIndexPath).row) else { fatalError("Unknown provider") }
        print("selected provider: \(provider)")
        
        performSegue(withIdentifier: loginSegueIdentifier, sender: provider.rawValue)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

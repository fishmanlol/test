//
//  SafariManager.swift
//  AiTmedPortal
//
//  Created by tongyi on 6/16/19.
//  Copyright © 2019 tongyi. All rights reserved.
//

import Foundation
import Alamofire

class Portal {
    
    enum Status {
        case notYet, success(url: String), failed(error: String), local
    }
    
    enum Role {
        case provider, patient
    }
    
    let SAFARI_NOT_EXIST = 0
    let SAFARI_TRUE = 1
    let SAFARI_FALSE = 2
    
    var status: Status = .notYet {
        didSet {
            NotificationCenter.default.post(name: Notification.Name.init(rawValue: "portalStatusChanged"), object: nil, userInfo: ["role": role, "oldStatus": oldValue, "newStatus": status])
        }
    }
    
    
    var configUrl: String!
    var openSafariKey: String! //1: open, 2:not open, 0: not exist
    var safariUrlKey: String!
    private var defaultUrl: String!
    var url: String!
    let role: Role
    
    init(role: Role) {
        self.role = role
        setup(for: role)
    }
    
    private func setup(for role: Role) {
        switch role {
        case .patient:
            self.configUrl = ""
            self.openSafariKey = ""
            self.safariUrlKey = ""
            self.defaultUrl = ""
            self.url = defaultUrl
        case .provider:
            self.configUrl = ""
            self.openSafariKey = ""
            self.safariUrlKey = ""
            self.defaultUrl = ""
            self.url = defaultUrl
        }
        
        updateStatus(for: role)
    }
    
    private func updateStatus(for role: Role) {
        let defaults = UserDefaults.standard
        //first check: user defaults
        let openSafari = defaults.integer(forKey: openSafariKey)
        
        if openSafari == 1 { //can decide in user defaults, open safari
            if let safariUrl = defaults.string(forKey: safariUrlKey) {
                url = safariUrl
            }
            status = .success(url: url)
        } else if openSafari == 2 { //can decide in user defaults, don't open safari
            status = .local
        } else { //can't decide, ask remote
            let realUrl = URL(string: url) ?? URL(string: defaultUrl)!
            Alamofire.request(realUrl).responseJSON { (response) in
                if let error = response.error {
                    print(error.localizedDescription)
                    self.status = .failed(error: error.localizedDescription)
                    self.url = self.defaultUrl
                    return
                }
                
                if let data = response.data, let json = try? JSONDecoder().decode(String.self, from: data) {
                   //Do next
                    self.url = json
                    self.status = .success(url: json)
                } else {
                    self.url = self.defaultUrl
                    self.status = .failed(error: "json decode error")
                }
            }
        }
        
    }
}


class SafariManager {
    
    let patient = Portal(role: .patient)
    let provider = Portal(role: .provider)
    
}

//
//  UUIDViewController.swift
//  ETAMessages
//
//  Created by taiyo on 7/3/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import UIKit

struct UUIDIndicator {
    var URLMessage: UILabel? = nil
}

class UUIDViewController: UIViewController {
    
    @IBOutlet weak var URLMessage: UILabel!
    
    var messageInUrl: String = ""
    
    static var uuidIndicator = UUIDIndicator()

    override func viewDidLoad() {
        //print("-- PseudoNotificationsViewController -- viewDidLoad()")
        super.viewDidLoad()
        
        if self.URLMessage != nil {
            
            UUIDViewController.uuidIndicator.URLMessage = self.URLMessage
        }
        
        //if UUIDViewController.uuidIndicator.URLMessage != nil {
        if self.messageInUrl != "" {
            UUIDViewController.uuidIndicator.URLMessage?.text = "REMOTE\n" + "\(String(describing: self.messageInUrl))"
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        //print("-- PseudoNotificationsViewController -- didReceiveMemoryWarning()")
        
    }
}

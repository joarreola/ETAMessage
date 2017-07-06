//
//  PseudoNotificationsViewController.swift
//  ETAMessages
//
//  Created by taiyo on 6/20/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import UIKit

class PseudoNotificationsViewController: UIViewController {

    @IBOutlet weak var display: UILabel!
    
    var message: String = ""
    
    override func viewDidLoad() {
        //print("-- PseudoNotificationsViewController -- viewDidLoad()")
        super.viewDidLoad()
        
        self.display.text = self.message
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        //print("-- PseudoNotificationsViewController -- didReceiveMemoryWarning()")

    }

}

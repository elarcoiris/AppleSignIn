//
//  OnboardingController.swift
//  AppleSignIn
//
//  Created by Prue Phillips on 15/9/20.
//  Copyright © 2020 Inspirare Tech. All rights reserved.
//

import Foundation
import UIKit

class OnboardingController: UIViewController {
    @IBOutlet weak var welcomeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let name = UserDefaults.standard.string(forKey: "firstName") else {return}
        welcomeLabel.text = "Welcome \(name)!"
    }
}

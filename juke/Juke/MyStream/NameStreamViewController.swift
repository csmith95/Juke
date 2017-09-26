//
//  NameStreamViewController.swift
//  Juke
//
//  Created by Conner Smith on 9/25/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Presentr
import SkyFloatingLabelTextField

class NameStreamViewController: UIViewController {

    @IBOutlet weak var textField: SkyFloatingLabelTextField!
    
    var placeholder: String!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textField.text = ""
        textField.errorMessage = ""
        textField.placeholder = placeholder
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didSelectCancel(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - Presentr Delegate

extension NameStreamViewController: PresentrDelegate {
    
    func presentrShouldDismiss(keyboardShowing: Bool) -> Bool {
        return !keyboardShowing
    }
    
}

// MARK: - UITextField Delegate

extension NameStreamViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.textField.errorMessage = ""
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if self.textField.text!.isEmpty {
            self.textField.errorMessage = "C'mon, give it a name!"
            return false
        }
        
        FirebaseAPI.setStreamName(name: self.textField.text!)
        self.textField.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
        return true
    }
    
}

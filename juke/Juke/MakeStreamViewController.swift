//
//  MakeStreamViewController.swift
//  Juke
//
//  Created by Conner Smith on 9/8/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField

class MakeStreamViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var streamTitleField: SkyFloatingLabelTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        streamTitleField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        streamTitleField.text = ""
        streamTitleField.errorMessage = ""
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        streamTitleField.errorMessage = ""
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if streamTitleField.text!.isEmpty {
            streamTitleField.errorMessage = "Enter a title for your stream"
            return false
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? MyStreamController {
            destination.streamName = streamTitleField.text!
        }
    }
}

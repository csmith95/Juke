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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        streamTitleField.endEditing(true)
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func startStreamingButtonPressed(_ sender: Any) {
        streamTitleField.endEditing(true)
        if streamTitleField.text!.isEmpty {
            streamTitleField.errorMessage = "Enter a title for your stream"
            return
        }
        
        FirebaseAPI.createNewStream(title: streamTitleField.text!) {
            self.performSegue(withIdentifier: "showStream", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? MyStreamController {
            dest.streamName = streamTitleField.text!
        }
    }
    
    // set status bar text to white
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
}

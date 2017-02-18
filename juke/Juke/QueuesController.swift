//
//  QueuesController.swift
//  Juke
//
//  Created by Thomas Jensen on 2/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

class QueuesController: UIViewController, UITableViewDelegate {
  

    @IBAction func addNewQueue(_ sender: Any) {
        let alert = UIAlertController(title: "New queue", message: "Enter a queue name", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = ""        }
        
        alert.addAction(UIAlertAction(title: "Dope", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            print("Text field: \(textField?.text)")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

//
//  LivePromoViewController.swift
//  Juke
//
//  Created by Conner Smith on 1/23/18.
//  Copyright © 2018 csmith. All rights reserved.
//

import UIKit
import AlamofireImage

class LivePromoViewController: UIViewController {

    @IBOutlet var matomaImage: UIImageView!
    @IBOutlet var dapImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        matomaImage.image = CircleFilter().filter(UIImage(named: "matoma")!)
        dapImage.image = CircleFilter().filter(UIImage(named: "DAP")!)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goBack(_ sender: Any) {
        performSegue(withIdentifier: "unwindToMyStream", sender: self)
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

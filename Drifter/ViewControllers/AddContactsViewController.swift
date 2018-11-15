//
//  AddContactsViewController.swift
//  Drifter
//
//  Created by Chris on 11/12/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import UIKit

class AddContactsViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  @IBAction func exitTouchUp(_ sender: Any) {
    performSegue(withIdentifier: "AddContactsToProfile", sender: nil)
  }
  

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

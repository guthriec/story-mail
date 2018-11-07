//
//  SignInViewController.swift
//  Drifter
//
//  Created by Chris on 11/2/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import UIKit

class SignInViewController: UIViewController {

  @IBOutlet weak var usernameField: UITextField!
  
  var viewModel: SignInViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    usernameField.delegate = self
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // this is so shitty
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: {
      self.usernameField.becomeFirstResponder()
    })
  }
    
  @IBAction func touchUpSignIn(_ sender: Any) {
    viewModel.setActiveUser(name: usernameField.text)
    performSegue(withIdentifier: "SignInToInbox", sender: nil)
  }
  
  @IBAction func touchUpCreate(_ sender: Any) {
    viewModel.setActiveUser(name: usernameField.text)
    performSegue(withIdentifier: "CreateToProfile", sender: nil)
  }
  
    // MARK: - Navigation

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if (segue.destination is StoryListViewController) {
      let storyList = segue.destination as! StoryListViewController
      if (segue.identifier == "SignInToInbox") {
        storyList.viewModel = self.viewModel.newInboxViewModel()
      }
    }
  }
}

extension SignInViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    print("in textFieldShouldReturn")
    textField.resignFirstResponder()
    return true
  }
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    print("in textFieldShouldBeginEditing")
    return true
  }
}

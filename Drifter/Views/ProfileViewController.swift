//
//  ProfileViewController.swift
//  Drifter
//
//  Created by Chris on 11/5/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {

  @IBOutlet weak var usernameLabel: UILabel!
  
  var viewModel: ProfileViewModel!
  
  func setUsernameLabel() {
    print("setting username")
    guard let activeUsername = viewModel.activeUsername else {
      return
    }
    usernameLabel.text = activeUsername
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setUsernameLabel()
    viewModel.setOnActiveUserChange(setUsernameLabel)
  }
    
  @IBAction func profileInboxTouchUp(_ sender: Any) {
    performSegue(withIdentifier: "ProfileToInbox", sender: nil)
  }
  
  @IBAction func switchAccountsTouchUp(_ sender: Any) {
    let switchAccountsActionSheet = UIAlertController(title: "Select Account", message: nil,
                                                      preferredStyle: .actionSheet)
    var existingAccountActions = Array<UIAlertAction>()
    let activeUsernameAction = UIAlertAction(title: viewModel.activeUsername, style: .default, handler: {_ in
      print("active here")
    })
    existingAccountActions.append(activeUsernameAction)
    if let localUsernames = viewModel.localUsernames {
      print(localUsernames)
      for name in localUsernames {
        if (name == viewModel.activeUsername) {
          continue
        }
        let inactiveUsernameAction = UIAlertAction(title: name, style: .default, handler: {_ in
          self.viewModel.changeActiveUsername(name: name)
        })
        existingAccountActions.append(inactiveUsernameAction)
      }
    }
    let newUserAction = UIAlertAction(title: "Create New Account", style: .default, handler: { _ in
      self.performSegue(withIdentifier: "ProfileToCreate", sender: nil)
    })
    for action in existingAccountActions {
      switchAccountsActionSheet.addAction(action)
    }
    switchAccountsActionSheet.addAction(newUserAction)
    self.present(switchAccountsActionSheet, animated: true, completion: nil)
  }
  
  @IBAction func returnToProfileView(segue: UIStoryboardSegue) {}

  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.destination is SignInViewController {
      let signIn = segue.destination as! SignInViewController
      signIn.viewModel = viewModel.newSignInViewModel()
    }
  }

}

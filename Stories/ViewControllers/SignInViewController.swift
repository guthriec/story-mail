//
//  SignInViewController.swift
//  Stories
//
//  Created by Chris on 11/2/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import UIKit

class SignInViewController: UIViewController {

  @IBOutlet weak var usernameField: UITextField!
  @IBOutlet weak var availabilityActivityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var availabilityDescription: UILabel!
  @IBOutlet weak var availabilityIndicator: UIImageView!
  
  @IBOutlet weak var registrationActivityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var registrationIndicator: UIImageView!
  @IBOutlet weak var registrationDescription: UILabel!
  
  @IBOutlet weak var getStartedButton: UIButton!
  
  var viewModel: SignInViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    usernameField.delegate = self
    hideAvailabilityResults()
    hideRegistrationResults()
  }
  
 /* override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // this is so shitty
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: {
      self.usernameField.becomeFirstResponder()
    })
  } */
    
  @IBAction func getStartedTouchUp(_ sender: Any) {
    getStartedButton.isEnabled = false
    registrationActivityIndicator.startAnimating()
    registrationDescription.text = "registering your username..."
    registrationDescription.isHidden = false

    viewModel.registerNewUser(name: usernameField.text, completion: {(status) in
      DispatchQueue.main.async {
        if (status == .Registered) {
          self.performSegue(withIdentifier: "SignInToInbox", sender: nil)
        } else {
          self.getStartedButton.isEnabled = true
          self.registrationActivityIndicator.stopAnimating()
          self.showRegistrationResults(status: status)
        }
      }
    })
  }
  
  /*@IBAction func signInTouchUp(_ sender: Any) {
    let switchAccountsActionSheet = UIAlertController(title: "Select Account", message: nil,
                                                      preferredStyle: .actionSheet)
    var existingAccountActions = Array<UIAlertAction>()
    if let localUsernames = viewModel.localUsernames() {
      for name in localUsernames {
        let inactiveUsernameAction = UIAlertAction(title: name, style: .default, handler: {_ in
          self.viewModel.setActiveUser(name: name)
          self.performSegue(withIdentifier: "SignInToInbox", sender: nil)
        })
        existingAccountActions.append(inactiveUsernameAction)
      }
    }
    let newUserAction = UIAlertAction(title: "Create New Account", style: .default, handler: nil)
    for action in existingAccountActions {
      switchAccountsActionSheet.addAction(action)
    }
    switchAccountsActionSheet.addAction(newUserAction)
    self.present(switchAccountsActionSheet, animated: true, completion: nil)
  }
  
  @IBAction func touchUpCreate(_ sender: Any) {
    registrationActivityIndicator.startAnimating()
    registrationDescription.text = "registering your username..."
    registrationDescription.isHidden = false

    viewModel.registerNewUser(name: usernameField.text, completion: {(success) in
      self.registrationActivityIndicator.stopAnimating()
      self.showRegistrationResults()
      if (success) {
        self.performSegue(withIdentifier: "CreateToProfile", sender: nil)
      }
    })
  } */
  
  @IBAction func goBackTouchUp(_ sender: Any) {
    self.performSegue(withIdentifier: "CreateToProfile", sender: nil)
  }
  
  
  
  func hideRegistrationResults() {
    registrationIndicator.isHidden = true
    registrationDescription.isHidden = true
  }
  
  func hideAvailabilityResults() {
    availabilityDescription.isHidden = true
    availabilityIndicator.isHidden = true
  }
  
  func showRegistrationResults(status: RegistrationStatus) {
    if status == .AlreadyRegistered {
      registrationDescription.text = "username not available"
    } else if status == .NetworkError {
      registrationDescription.text = "error connecting to server"
    } else {
      registrationDescription.text = "an unknown error occurred..."
    }
    registrationDescription.isHidden = false
    registrationIndicator.isHidden = false
  }
  
  func showAvailabilityResults(status: AvailabilityStatus) {
    if status == .Available {
      // TODO: move this logic to viewmodel
      availabilityDescription.text = "username available"
      availabilityIndicator.image = UIImage(named: "CheckIconGreen")
    } else if status == .Unavailable {
      availabilityDescription.text = "username not available"
      availabilityIndicator.image = UIImage(named: "CrossIconRed")
    } else if status == .NetworkError {
      availabilityDescription.text = "error connecting to server"
      availabilityIndicator.image = UIImage(named: "CrossIconRed")
    } else if status == .UnknownError {
      availabilityDescription.text = "an unknown error occurred..."
      availabilityIndicator.image = UIImage(named: "CrossIconRed")
    }
    availabilityDescription.isHidden = false
    availabilityIndicator.isHidden = false
  }
  
  func checkAvailability() {
    availabilityActivityIndicator.startAnimating()
    availabilityDescription.text = "checking username availability..."
    availabilityDescription.isHidden = false
    viewModel.checkUsernameAvailable(name: usernameField.text, completion: {(status) in
      DispatchQueue.main.async {
        self.availabilityActivityIndicator.stopAnimating()
        self.showAvailabilityResults(status: status)
      }
    })
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
    textField.resignFirstResponder()
    checkAvailability()
    return true
  }
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    hideAvailabilityResults()
    return true
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    return viewModel.allCharactersOkay(string: string)
  }
}


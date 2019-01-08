//
//  ProfileViewController.swift
//  Stories
//
//  Created by Chris on 11/5/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {

  @IBOutlet weak var usernameLabel: UILabel!
  @IBOutlet weak var contactSearchBar: UISearchBar!
  @IBOutlet weak var contactList: UITableView!
  
  var viewModel: ProfileViewModel!
  
  func setUsernameLabel() {
    print("setting username")
    guard let activeUsername = viewModel.activeUsername else {
      usernameLabel.text = "Account Deleted"
      return
    }
    usernameLabel.text = activeUsername
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setUsernameLabel()
    viewModel.setOnActiveUserChange(setUsernameLabel)
    contactSearchBar.delegate = self
    contactList.dataSource = self
    contactList.allowsSelection = false
  }
    
  @IBAction func profileInboxTouchUp(_ sender: Any) {
    if (viewModel.activeUsername == nil) {
      let mustLogInAlert = UIAlertController(title: "Choose an Account",
                                             message: "You must be signed in to use Stories",
                                             preferredStyle: .alert)
      mustLogInAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      self.present(mustLogInAlert, animated: false, completion: nil)
    } else {
      performSegue(withIdentifier: "ProfileToInbox", sender: nil)
    }
  }
  
  @IBAction func addContactTouchUp(_ sender: Any) {
    performSegue(withIdentifier: "ShowAddContacts", sender: nil)
  }
  
  func presentAccountsSelector() {
    let switchAccountsActionSheet = UIAlertController(title: "Select Account", message: nil,
                                                      preferredStyle: .actionSheet)
    var existingAccountActions = Array<UIAlertAction>()
    if (viewModel.activeUsername != nil) {
      let activeUsernameAction = UIAlertAction(title: viewModel.activeUsername, style: .default, handler: {_ in
        print("active here")
      })
      existingAccountActions.append(activeUsernameAction)
    }
    if let localUsernames = viewModel.localUsernames {
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
  
  @IBAction func switchAccountsTouchUp(_ sender: Any) {
    presentAccountsSelector()
  }
  
  @IBAction func deleteAccountTouchUp(_ sender: Any) {
    let confirmDeleteAlert = UIAlertController(title: "Confirm",
                                               message: "Delete user: \(viewModel.activeUsername ?? "Nonexistent Account...")",
                                               preferredStyle: .alert)
    confirmDeleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {_ in
      return
    }))
    confirmDeleteAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {_ in
      do {
        try self.viewModel.deleteActiveUser()
      } catch {
        // TODO: UIALert error
        print("Error deleting account")
        print(error)
      }
      self.presentAccountsSelector()
    }))
    self.present(confirmDeleteAlert, animated: true, completion: nil)
  }
  
  @IBAction func addContactsTouchUp(_ sender: Any) {
    self.performSegue(withIdentifier: "ProfileToAddContacts", sender: nil)
  }
  
  @IBAction func returnToProfileView(segue: UIStoryboardSegue) {}

  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.destination is SignInViewController {
      let signIn = segue.destination as! SignInViewController
      signIn.viewModel = viewModel.newSignInViewModel()
    }
    if segue.destination is AddContactsViewController {
      let addContacts = segue.destination as! AddContactsViewController
      addContacts.viewModel = viewModel.newAddContactsViewModel()
    }
  }

}

extension ProfileViewController : UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    self.viewModel.fetchContactsWithQuery(username: searchText)
    self.contactList.reloadData()
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }
}

class ContactCell: UITableViewCell {
  weak var delegate: ContactCellDelegate?
  
  var username: String?
  
  @IBOutlet weak var usernameLabel: UILabel!
  /*@IBAction func sendStoryTouchUp(_ sender: Any) {
    delegate?.sendStory(delegatedFrom: self)
  }*/
}

protocol ContactCellDelegate : class {
  // func sendStory(delegatedFrom cell: ContactCell)
}

/*extension ProfileViewController : ContactCellDelegate {
  func sendStory(delegatedFrom cell: ContactCell) {
    viewModel.setStoryIntention(username: cell.username)
    self.performSegue(withIdentifier: "ProfileToCamera", sender: nil)
  }
}*/

extension ProfileViewController : UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    //print("In tableView numOfRowsInSection")
    return viewModel.numContacts()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactCell
    cell.username = viewModel.contactAt(indexPath.item)
    cell.usernameLabel.text = cell.username
    //cell.delegate = self
    return cell
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    if (viewModel.numContacts() > 0) {
      return 1
    } else {
      return 0
    }
  }
}

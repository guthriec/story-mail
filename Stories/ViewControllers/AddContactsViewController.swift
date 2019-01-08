//
//  AddContactsViewController.swift
//  Stories
//
//  Created by Chris on 11/12/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import UIKit

class AddContactsViewController: UIViewController {

  var viewModel: AddContactsViewModel!
  @IBOutlet weak var contactSearchTable: UITableView!
  @IBOutlet weak var contactSearchBar: UISearchBar!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    contactSearchBar.delegate = self
    contactSearchTable.dataSource = self
    viewModel.setOnSearchResultChange({
      DispatchQueue.main.async {
        self.contactSearchTable.reloadData()
      }
    })
  }
  
  @IBAction func exitTouchUp(_ sender: Any) {
    performSegue(withIdentifier: "AddContactsToProfile", sender: nil)
  }

}

//TODO: most of these extensions are extremeily similar to CameraViewController
extension AddContactsViewController : UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    if searchText.count > 0 {
      self.viewModel.searchUsersFor(searchText, completion: { success in
        if (!success) {
          print("Search failed!")
        }
      })
    }
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }
}

protocol ContactSearchResultCellDelegate : class {
  func toggleContact(delegatedFrom cell: ContactSearchResultCell)
}

class ContactSearchResultCell: UITableViewCell {
  weak var delegate: ContactSearchResultCellDelegate?
  
  @IBOutlet weak var toggleContactButton: UIButton!
  @IBOutlet weak var usernameLabel: UILabel!
  @IBAction func toggleContactTouchUp(_ sender: Any) {
    delegate?.toggleContact(delegatedFrom: self)
  }
  var username: String?
}

extension AddContactsViewController : UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.numSearchResults()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ContactSearchResult",
                                             for: indexPath) as! ContactSearchResultCell
    cell.username = viewModel.searchResultAt(indexPath.item)
    cell.usernameLabel?.text = cell.username
    if (viewModel.isContact(username: cell.username)) {
      let alreadyAddedImage = UIImage(named: "CheckIcon") as UIImage?
      cell.toggleContactButton.setImage(alreadyAddedImage, for: .normal)
    } else {
      let addImage = UIImage(named: "AddIcon") as UIImage?
      cell.toggleContactButton.setImage(addImage, for: .normal)
    }
    cell.delegate = self
    return cell
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    if (viewModel.numSearchResults() > 0) {
      return 1
    } else {
      return 0
    }
  }
}

extension AddContactsViewController : ContactSearchResultCellDelegate {
  func toggleContact(delegatedFrom cell: ContactSearchResultCell) {
    do {
      guard let username = cell.username else {
        print("no username?!?!??")
        return
      }
      try self.viewModel.toggleContact(username: username)
    } catch {
      //TODO: handle error
      print(error)
    }
  }
}

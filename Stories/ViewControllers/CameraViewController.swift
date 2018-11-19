//
//  CameraViewController.swift
//  Stories
//
//  Created by Chris on 8/27/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import UIKit
import Photos


class CameraViewController: UIViewController, UITableViewDelegate {
  
  //MARK: properties
  var viewModel: CameraViewModel!
  var isReplying: Bool! {
    return viewModel.isReplying()
  }
  
  @IBOutlet weak var captureButton: UIButton!
  @IBOutlet weak var cameraSwitcher: UIButton!
  @IBOutlet weak var inboxButton: UIButton!
  @IBOutlet weak var capturePreview: UIView!
  
  @IBOutlet var replyConfirmationView: UIView!
  @IBOutlet weak var replyConfirmationPreview: UIImageView!
  
  @IBOutlet var newStoryConfirmationView: UIView!
  @IBOutlet weak var newStoryConfirmationPreview: UIImageView!
  
  @IBOutlet weak var newStoryContributors: UITableView!
  @IBOutlet weak var replyContributors: UITableView!
  
  
  var confirmationView: UIView! {
    if isReplying {
      return replyConfirmationView
    } else {
      return newStoryConfirmationView
    }
  }
  
  var confirmationPreview: UIImageView! {
    if isReplying {
      return replyConfirmationPreview
    } else {
      return newStoryConfirmationPreview
    }
  }
  
  var contributors: UITableView! {
    if isReplying {
      return replyContributors
    } else {
      return newStoryContributors
    }
  }
  
  @IBOutlet weak var contributorSearchBar: UISearchBar!
  @IBOutlet weak var contributorSearchResults: UITableView!
  
  var replyContributorTableDelegate: ContributorTableDelegate?
  var replyContributorTableDataSource : ContributorTableDataSource?
  
  var newStoryContributorTableDelegate: ContributorTableDelegate?
  var newStoryContributorTableDataSource : ContributorTableDataSource?


  let cameraWorker = CameraWorker()
  
  //MARK: actions
  /*@IBAction func toggleFlash(_ sender: UIButton) {
    if cameraWorker.flashMode == .on {
      cameraWorker.flashMode = .off
    } else {
      cameraWorker.flashMode = .on
    }
  }*/
  
  @IBAction func switchCameras(_ sender: UIButton) {
    do {
      try cameraWorker.switchCameras()
    } catch {
      print(error)
    }
  }
  
  @IBAction func captureImage(_ sender: UIButton) {
    cameraWorker.captureImage(completionHandler: {(image, error) in
      guard let image = image else {
        print(error ?? "Image capture error")
        return
      }
      guard let imagePNG = image.jpegData(compressionQuality: 1.0) else {
        print("error converting to JPEG")
        return
      }
      self.viewModel.handleCapture(backgroundImagePNG: imagePNG)

      self.confirmationPreview.image = self.viewModel.capturedImage
      DispatchQueue.main.async {
        self.view.addSubview(self.confirmationView)
      }
      //self.performSegue(withIdentifier: "CameraToStoryList", sender: nil)
    })
  }
  
  @IBAction func showInbox(_ sender: Any) {
    self.performSegue(withIdentifier: "CameraToStoryList", sender: nil)
  }
    
  @IBAction func touchUpSend(_ sender: Any) {
    do {
      try viewModel.handleSend(completion: {(success) in
        if (success) {
          self.performSegue(withIdentifier: "CameraToStoryList", sender: nil)
        }
      })
    } catch {
      print("error in handle send: ", error)
    }
  }
  
  func reloadAllTables() {
    DispatchQueue.main.async {
      self.replyContributors.reloadData()
      self.newStoryContributors.reloadData()
      self.contributorSearchResults.reloadData()
    }
  }
  
  //MARK: lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    captureButton.layer.cornerRadius = 16
    captureButton.layer.borderColor = UIColor.white.cgColor
    captureButton.layer.borderWidth = 2.0
    
    cameraSwitcher.layer.cornerRadius = 4
    cameraSwitcher.layer.borderColor = UIColor.white.cgColor
    cameraSwitcher.layer.borderWidth = 0.5

    // TODO: take out gesture recognizer on confirmation view
    let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self,
                                                          action: #selector(CameraViewController.showInbox(_:)))
    swipeGestureRecognizer.direction = UISwipeGestureRecognizer.Direction.down
    self.view.addGestureRecognizer(swipeGestureRecognizer)
    
    cameraWorker.prepare{(err) in
      if let err = err {
        print(err)
      }
      try? self.cameraWorker.displayPreview(insideOf: self.capturePreview)
    }
    
    confirmationView.frame = self.view.frame
    
    // Get rid of extra separators
    contributorSearchResults.tableFooterView = UIView()
    replyContributors.tableFooterView = UIView()
    newStoryContributors.tableFooterView = UIView()
    
    contributorSearchBar.autocapitalizationType = .none
    
    replyContributorTableDelegate = ContributorTableDelegate(viewModel: self.viewModel)
    
    replyContributorTableDataSource = ContributorTableDataSource(viewModel: self.viewModel,
                                                                 cellDelegate: self.replyContributorTableDelegate!)
    
    newStoryContributorTableDelegate = ContributorTableDelegate(viewModel: self.viewModel)
    
    newStoryContributorTableDataSource = ContributorTableDataSource(viewModel: self.viewModel,
                                                                    cellDelegate: self.newStoryContributorTableDelegate!)

    
    contributorSearchBar.delegate = self
    contributorSearchResults.delegate = self
    contributorSearchResults.dataSource = self
    
    replyContributors.delegate = replyContributorTableDelegate
    replyContributors.dataSource = replyContributorTableDataSource
    
    newStoryContributors.delegate = newStoryContributorTableDelegate
    newStoryContributors.dataSource = newStoryContributorTableDataSource

    reloadAllTables()
    
    viewModel.setOnContributorChange({
      self.reloadAllTables()
    })
    
    // Initial (empty) search
    viewModel.searchUsersFor("", completion: { success in
      if (!success) {
        print("Initial search failed!")
      } else {
        self.contributorSearchResults.reloadData()
      }
    })

  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

protocol ContributorSearchResultsCellDelegate : class {
  func toggleContributor(delegatedFrom cell: ContributorSearchResultsCell)
}

class ContributorSearchResultsCell: UITableViewCell {
  weak var delegate: ContributorSearchResultsCellDelegate?
  
  @IBOutlet weak var toggleContributorButton: UIButton!
  @IBOutlet weak var usernameLabel: UILabel!
  @IBAction func toggleContributorTouchUp(_ sender: Any) {
    delegate?.toggleContributor(delegatedFrom: self)
  }
  var username: String?
}

extension CameraViewController : UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.numSearchResults()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ContributorSearchResult",
                                             for: indexPath) as! ContributorSearchResultsCell
    cell.username = viewModel.contributorResultAt(indexPath.item)
    cell.usernameLabel?.text = cell.username
    if (viewModel.isContributor(cell.username)) {
      let alreadyAddedImage = UIImage(named: "CheckIcon") as UIImage?
      cell.toggleContributorButton.setImage(alreadyAddedImage, for: .normal)
    } else {
      let addImage = UIImage(named: "AddIcon") as UIImage?
      cell.toggleContributorButton.setImage(addImage, for: .normal)
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

extension CameraViewController : ContributorSearchResultsCellDelegate {
  func toggleContributor(delegatedFrom cell: ContributorSearchResultsCell) {
    self.viewModel.toggleContributor(cell.username)
  }
}

extension CameraViewController : UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    self.viewModel.searchUsersFor(searchText, completion: { success in
      if (!success) {
        print("Search failed!")
      } else {
        self.contributorSearchResults.reloadData()
      }
    })
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }
}

protocol ContributorCellDelegate : class {
  func removeContributor(delegatedFrom cell: ContributorCell)
}

class ContributorCell : UITableViewCell {
  @IBOutlet weak var usernameLabel: UILabel!
  weak var delegate: ContributorCellDelegate?
  var username: String?
  @IBAction func removeContributorTouchUp(_ sender: Any) {
    self.delegate?.removeContributor(delegatedFrom: self)
  }
}

class ContributorTableDelegate : NSObject, UITableViewDelegate, ContributorCellDelegate {
  let viewModel: CameraViewModel
  
  init(viewModel: CameraViewModel) {
    self.viewModel = viewModel
  }
  
  func removeContributor(delegatedFrom cell: ContributorCell) {
    viewModel.removeContributor(cell.username)
  }
}

class ContributorTableDataSource : NSObject, UITableViewDataSource {
  let viewModel: CameraViewModel
  let cellDelegate: ContributorCellDelegate
  
  init(viewModel: CameraViewModel, cellDelegate: ContributorCellDelegate) {
    self.viewModel = viewModel
    self.cellDelegate = cellDelegate
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    //print("number of contributors should be: ", viewModel.numContributors())
    return viewModel.numContributors()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Contributor",
                                             for: indexPath) as! ContributorCell
    cell.username = viewModel.contributorAt(indexPath.item)
    cell.usernameLabel?.text = cell.username
    cell.delegate = self.cellDelegate
    return cell
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    if (viewModel.numContributors() > 0) {
      return 1
    } else {
      return 0
    }
  }
}
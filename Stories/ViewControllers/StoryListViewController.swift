//
//  StoryListViewController.swift
//  Stories
//
//  Created by Chris on 10/23/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//


import UIKit

@IBDesignable
class IndicatorDot: UIView {
  
  override func draw(_ rect: CGRect) {
    let dotPath = UIBezierPath(ovalIn: rect)
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = dotPath.cgPath
    shapeLayer.fillColor = UIColor.red.cgColor
    layer.addSublayer(shapeLayer)
  }
  
}

class StoryListViewController: UIViewController {
  //MARK: properties
  var viewModel: StoryListViewModel!
  @IBOutlet weak var inboxLoadingIndicator: UIActivityIndicatorView!
  @IBOutlet weak var newStoryIndicator: IndicatorDot!
  
  //MARK: actions
  @IBAction func newStory(_ sender: Any) {
    performSegue(withIdentifier: "ShowCamera", sender: nil)
  }
  
  @IBAction func archiveInboxTouchUp(_ sender: Any) {
    performSegue(withIdentifier: "ArchiveToInbox", sender: nil)
  }
 
  @IBAction func inboxArchiveTouchUp(_ sender: Any) {
    performSegue(withIdentifier: "InboxToArchive", sender: nil)
  }
  
  @IBAction func inboxProfileTouchUp(_ sender: Any) {
    performSegue(withIdentifier: "InboxToProfile", sender: nil)
  }
  
  @IBAction func inboxTouchUp(_ sender: Any) {
    self.viewModel.refreshStories()
  }
  
  @IBAction func returnToStoryListView(segue: UIStoryboardSegue) {}
  
  func onStorySyncStart() {
    if let inboxLoadingIndicator = inboxLoadingIndicator {
      DispatchQueue.main.async {
        inboxLoadingIndicator.startAnimating()
      }
    }
  }
  
  func onStorySyncComplete(success: Bool) {
    //print("In viewcontroller onStoryFetchComplete")
    if let inboxLoadingIndicator = inboxLoadingIndicator {
      DispatchQueue.main.async {
        inboxLoadingIndicator.stopAnimating()
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    viewModel.setOnStorySyncStart(onStorySyncStart)
    viewModel.setOnStorySyncComplete(onStorySyncComplete)
    if let newStoryIndicator = newStoryIndicator {
      newStoryIndicator.isHidden = true
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  //MARK: navigation
  //initialize and pass in fresh inboxtableviewmodel to inboxtableview controller
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.destination is StoryListTableViewController {
      let storyListTable = segue.destination as! StoryListTableViewController
      if (segue.identifier == "ArchiveTableEmbed") {
        storyListTable.viewModel = viewModel.newArchiveTableViewModel()
        storyListTable.tableViewCellIdentifier = "ArchiveTableViewCell"
        storyListTable.emptyText = "No archived stories"
      } else {
        storyListTable.viewModel = viewModel.newInboxTableViewModel()
        storyListTable.tableViewCellIdentifier = "InboxTableViewCell"
        storyListTable.emptyText = "Your inbox is empty! \n \n \n If you're looking for something to do, you could try starting a new story..."
      }
    }
    if segue.destination is StoryListViewController {
      let storyList = segue.destination as! StoryListViewController
      if (segue.identifier == "InboxToArchive") {
        storyList.viewModel = viewModel.newArchiveViewModel()
      }
    }
    if segue.destination is CameraViewController {
      let camera = segue.destination as! CameraViewController
      camera.viewModel = self.viewModel.newCameraViewModel()
    }
    if segue.destination is ProfileViewController {
      let profile = segue.destination as! ProfileViewController
      profile.viewModel = self.viewModel.newProfileViewModel()
    }
    if segue.destination is StoryViewController {
      let story = segue.destination as! StoryViewController
      story.viewModel = self.viewModel.newStoryViewModel()
    }
  }
}

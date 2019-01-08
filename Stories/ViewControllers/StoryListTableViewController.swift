//
//  StoryListTableViewController.swift
//  Stories
//
//  Created by Chris on 10/23/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation
import UIKit

//MARK: Views
protocol StoryCellDelegate: class {
  func deleteCell(delegatedFrom cell: StoryListTableViewCell)
  func archiveCell(delegatedFrom cell: StoryListTableViewCell)
  func sendCellToInbox(delegatedFrom cell: StoryListTableViewCell)
}

/*class StoryCollectionView: UICollectionView {
 override func  {
    super.layoutSubviews()
    guard self.numberOfSections == 1 else {
      return
    }
    let lastItemIndexPath = IndexPath(item: self.numberOfItems(inSection: 0) - 1,
                                      section: 0)
    print("In layout subviews with last index path: ", lastItemIndexPath)
    self.scrollToItem(at: lastItemIndexPath,
                                     at: .right,
                                     animated: false)

  }
}*/

class StoryListTableViewCell: UITableViewCell {
  @IBOutlet private weak var storyCollectionView: UICollectionView!
  weak var delegate: StoryCellDelegate?
  var storyId: String?
  
  @IBOutlet weak var contributorsLabel: UILabel!
  
  @IBAction func archiveStory(_ sender: Any) {
    delegate?.archiveCell(delegatedFrom: self)
  }
  
  @IBAction func deleteStory(_ sender: Any) {
    self.delegate?.deleteCell(delegatedFrom: self)
  }
  
  @IBAction func sendStoryToInbox(_ sender: Any) {
    delegate?.sendCellToInbox(delegatedFrom: self)
  }
  
  func scrollToPosition(index: Int) {
    if index >= storyCollectionView.numberOfItems(inSection: 0) {
      return
    }
    let itemIndexPath = IndexPath(item: index,
                                  section: 0)
    //print("In scrollToPosition with last index path: ", itemIndexPath)
    storyCollectionView.scrollToItem(at: itemIndexPath,
                                     at: .right,
                                     animated: false)
  }
  
  func scrollToEnd() {
    self.scrollToPosition(index: self.storyCollectionView.numberOfItems(inSection: 0) - 1)
  }

  
  func setStoryTag(forRow row: Int) {
    storyCollectionView.tag = row
    storyCollectionView.reloadData()
  }
  
  func setStoryLayoutDelegate(delegate: StoryLayoutDelegate) {
    if let layout = storyCollectionView.collectionViewLayout as? StoryLayout {
      layout.delegate = delegate
    }
  }
  
  func invalidateStoryLayout() {
    storyCollectionView.collectionViewLayout.invalidateLayout()
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
}

protocol ReplyCellDelegate: class {
  func reply(delegatedFrom cell: ReplyCell)
}

class ReplyCell: UICollectionViewCell {
  weak var delegate: ReplyCellDelegate?
  var storyId: String?
  
  @IBAction func reply(_ sender: Any) {
    delegate?.reply(delegatedFrom: self)
  }
}

protocol PageCellDelegate: class {
  func goToPage(delegatedFrom cell: PageCell)
}

class PageCell: UICollectionViewCell {
  weak var delegate: PageCellDelegate?
  var storyId: String?
  var pageIndex: Int?
  
  @objc func imageTapDetected() {
    delegate?.goToPage(delegatedFrom: self)
  }
}

// MARK: ViewControllers
class StoryListTableViewController: UITableViewController {
  var viewModel: StoryListTableViewModel!
  var tableViewCellIdentifier: String!
  var emptyText: String!
  
  func scrollAllToEnd() {
    let numRows = self.tableView.numberOfRows(inSection: 0)
    for row in 0 ..< numRows {
      print("looping through rows")
      print(self.tableView.cellForRow(at: IndexPath(row: row, section: 0)) ?? "None")
      guard let cell = self.tableView.cellForRow(at: IndexPath(row: row, section: 0)) as! StoryListTableViewCell? else {
        print("Couldn't extract table cell")
        continue
      }
      cell.scrollToEnd()
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.allowsSelection = false
    DispatchQueue.main.async {
      //self.scrollAllToEnd()
    }
    viewModel.setOnStoryListChange({
      DispatchQueue.main.async {
        self.tableView.reloadData()
        //self.scrollAllToEnd()
      }
    })
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  
  // MARK: - Table view data source
  override func numberOfSections(in tableView: UITableView) -> Int {
    var res: Int = 0
    if (viewModel.numStories() > 0) {
      res = 1
      tableView.backgroundView = nil
    } else {
      let emptyContainer: UIView = UIView(frame: CGRect( x: tableView.bounds.midX - 130,
                                                         y: tableView.bounds.minY,
                                                         width: CGFloat(260),
                                                         height: tableView.bounds.size.height - 60))
      let emptyLabel: UILabel = UILabel(frame: CGRect(x: tableView.bounds.midX - 130,
                                                      y: tableView.bounds.minY,
                                                      width: CGFloat(260),
                                                      height: tableView.bounds.size.height - 60))
      emptyLabel.preferredMaxLayoutWidth = emptyLabel.bounds.width
      emptyLabel.clipsToBounds = true
      emptyLabel.text = self.emptyText
      emptyLabel.textAlignment = .center
      emptyLabel.textColor = UIColor.black
      emptyLabel.font = emptyLabel.font.withSize(18)
      emptyLabel.numberOfLines = 0
      emptyLabel.lineBreakMode = .byWordWrapping
      tableView.backgroundView = emptyContainer
      emptyContainer.addSubview(emptyLabel)
    }
    return res
  }

  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.numStories()
  }
  
  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath)
      as! StoryListTableViewCell
    //cell.invalidateStoryLayout()
    cell.setStoryTag(forRow: indexPath.item)
    cell.setStoryLayoutDelegate(delegate: self)
    cell.storyId = viewModel.extendedStoryIdAt(index: indexPath.item)
    cell.contributorsLabel.text = self.viewModel.contributorsTextAt(index: indexPath.item)
    DispatchQueue.main.async {
      cell.scrollToPosition(index: self.viewModel.lastPositionAt(storyIndex: indexPath.item))
    }
    cell.delegate = self
    return cell
  }
}

extension StoryListTableViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  func collectionView(_ collectionView: UICollectionView,
                      numberOfItemsInSection section: Int) -> Int {
    //print("calculating number of items in section 0, tag: ", collectionView.tag)
    //print("Num pages: ", viewModel.numPagesInManagedStoryAt(index: collectionView.tag))
    return viewModel.numPagesInExtendedStoryAt(index: collectionView.tag) + 1
  }
  
  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    //print("calling cellForItemAt: ", indexPath, " with item number: ", indexPath.item)
    let endIndex = collectionView.numberOfItems(inSection: 0) - 1

    if (indexPath.item == endIndex) {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ReplyCell",
                                                    for: indexPath) as! ReplyCell
      cell.delegate = self
      cell.storyId = viewModel.extendedStoryIdAt(index: collectionView.tag)
      return cell
    }
    let page = self.viewModel.nthPageInExtendedStoryAt(storyIndex: collectionView.tag, pageIndex: indexPath.item)
    guard let status = page?.status, let image = page?.backgroundImagePNG, let timestamp = page?.timeString, let authorName = page?.authorName else {
      print("not enough page data supplied")
      return collectionView.dequeueReusableCell(withReuseIdentifier: "ErrorCell", for: indexPath)
    }
    if status == .OK {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StoryCell",
                                                    for: indexPath) as! PageCell
      cell.delegate = self
      cell.storyId = viewModel.extendedStoryIdAt(index: collectionView.tag)
      cell.pageIndex = indexPath.item
      guard let imageView = cell.contentView.subviews[0] as? UIImageView else {
        print("cell content view not an imageView!")
        return cell
      }
      guard let timestampLabel = cell.contentView.subviews[1].subviews[0] as? UILabel else {
        print("selected view is not the timestamp label you were looking for")
        return cell
      }
      guard let authorLabel = cell.contentView.subviews[2].subviews[0] as? UILabel else {
        print("selected view is not the author label you were looking for")
        return cell
      }
      DispatchQueue.main.async {
        imageView.image = image
        // register tap recognizer
        imageView.isUserInteractionEnabled = true
        let singleTap = UITapGestureRecognizer(target: cell, action: #selector(PageCell.imageTapDetected))
        imageView.addGestureRecognizer(singleTap)
        timestampLabel.text = timestamp
        authorLabel.text = authorName
      }
      return cell
    } else if status == .Sending {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SendingCell", for: indexPath)
      guard let imageView = cell.contentView.subviews[0] as? UIImageView else {
        print("cell content view not an imageView!")
        return cell
      }
      guard let activityIndicator = cell.contentView.subviews[1] as? UIActivityIndicatorView else {
        print("selected view is not the activity indicator you were looking for")
        return cell
      }
      imageView.image = image
      activityIndicator.startAnimating()
      return cell
    } else {
      return collectionView.dequeueReusableCell(withReuseIdentifier: "ErrorCell", for: indexPath)
    }
  }
}

extension StoryListTableViewController: StoryCellDelegate {
  func deleteCell(delegatedFrom cell: StoryListTableViewCell) {
    let confirmationAlert = UIAlertController(title: "Confirm Delete",
                                              message: "You can't undo this action",
                                              preferredStyle: .alert)
    confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    confirmationAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {_ in
      do {
        try self.viewModel.deleteStory(byId: cell.storyId)
      } catch {
        // TODO: non-crashing error alert here
        print("Error Deleting Story")
        print(error)
      }
    }))
    self.present(confirmationAlert, animated: false, completion: nil)
  }
  func archiveCell(delegatedFrom cell: StoryListTableViewCell) {
    do {
      try viewModel.archiveStory(byId: cell.storyId)
    } catch {
      // TODO: non-crashing error alert here
      print("Error Archiving Story")
      print(error)
    }
  }
  func sendCellToInbox(delegatedFrom cell: StoryListTableViewCell) {
    do {
      try viewModel.unArchiveStory(byId: cell.storyId)
    } catch {
      // TODO: non-crashing error alert here
      print("Error Unrchiving Story")
      print(error)
    }

  }
}

extension StoryListTableViewController: ReplyCellDelegate {
  func reply(delegatedFrom cell: ReplyCell) {
    if let storyId = cell.storyId {
      viewModel.setReplyStoryFromId(storyId: storyId)
      parent?.performSegue(withIdentifier: "ShowCamera", sender: nil)
    }
  }
}

extension StoryListTableViewController: PageCellDelegate {
  func goToPage(delegatedFrom cell: PageCell) {
    guard let storyId = cell.storyId, let storyIndex = viewModel.storyIndexFromId(storyId: storyId) else {
      return
    }
    guard let pageIndex = cell.pageIndex else {
      return
    }
    viewModel.setStoryViewerStartingPoint(storyIndex: storyIndex, pageIndex: pageIndex)
    parent?.performSegue(withIdentifier: "ShowStory", sender: nil)
  }
}

extension StoryListTableViewController: StoryLayoutDelegate {
  func collectionView(_ collectionView: UICollectionView,
                      widthForCellAtIndexPath indexPath: IndexPath) -> CGFloat {
    let endIndex = collectionView.numberOfItems(inSection: 0) - 1
    if (indexPath.item == endIndex) {
      return CGFloat(70)
    } else {
      return CGFloat(147)
    }
  }
}


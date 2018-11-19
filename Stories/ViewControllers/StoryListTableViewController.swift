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

class StoryListTableViewCell: UITableViewCell {
  @IBOutlet private weak var storyCollectionView: UICollectionView!
  weak var delegate: StoryCellDelegate?
  var storyId: String?
  
  @IBOutlet weak var contributorsLabel: UILabel!
  
  @IBAction func archiveStory(_ sender: Any) {
    delegate?.archiveCell(delegatedFrom: self)
  }
  
  @IBAction func deleteStory(_ sender: Any) {
    delegate?.deleteCell(delegatedFrom: self)
  }
  
  @IBAction func sendStoryToInbox(_ sender: Any) {
    delegate?.sendCellToInbox(delegatedFrom: self)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    guard storyCollectionView.numberOfSections == 1 else {
      return
    }
    /* guard storyCollectionView.numberOfItems(inSection: 0) > 0 else {
      return
    } */
    let lastItemIndexPath = IndexPath(item: storyCollectionView.numberOfItems(inSection: 0) - 1,
                                      section: 0)
    print("In layout subviews with last index path: ", lastItemIndexPath)
    storyCollectionView.scrollToItem(at: lastItemIndexPath,
                                     at: .right,
                                     animated: false)
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

// MARK: ViewControllers
class StoryListTableViewController: UITableViewController {
  var viewModel: StoryListTableViewModel!
  var tableViewCellIdentifier: String!
  var emptyText: String!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.allowsSelection = false
    viewModel.setOnStoryChange({
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    })
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: - Table view data source
  override func numberOfSections(in tableView: UITableView) -> Int {
    var res: Int = 0
    if (viewModel.numManagedStories() > 0) {
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
    return viewModel.numManagedStories()
  }
  
  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath)
      as! StoryListTableViewCell
    cell.invalidateStoryLayout()
    cell.setStoryTag(forRow: indexPath.item)
    cell.setStoryLayoutDelegate(delegate: self)
    cell.storyId = viewModel.managedStoryIdAt(index: indexPath.item)
    cell.contributorsLabel.text = viewModel.contributorsTextAt(index: indexPath.item)
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
    return viewModel.numPagesInManagedStoryAt(index: collectionView.tag) + 1
  }
  
  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    //print("calling cellForItemAt: ", indexPath, " with item number: ", indexPath.item)
    if (indexPath.item == collectionView.numberOfItems(inSection: 0) - 1) {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ReplyCell",
                                                    for: indexPath) as! ReplyCell
      cell.delegate = self
      // cell.storyId = viewModel.storyIdAt(storyIndex: collectionView.tag)
      cell.storyId = viewModel.managedStoryIdAt(index: collectionView.tag)
      return cell
    }
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StoryCell",
                                                  for: indexPath)
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
    let page = viewModel.nthPageInManagedStoryAt(storyIndex: collectionView.tag, pageIndex: indexPath.item)
    guard let image = page?.backgroundImagePNG, let timestamp = page?.timeString,
      let authorName = page?.authorName else {
      print("not enough page data supplied")
      return cell
    }
    imageView.image = image
    timestampLabel.text = timestamp
    authorLabel.text = authorName
    return cell
  }
}

extension StoryListTableViewController: StoryCellDelegate {
  func deleteCell(delegatedFrom cell: StoryListTableViewCell) {
    viewModel.deleteStory(byId: cell.storyId)
  }
  func archiveCell(delegatedFrom cell: StoryListTableViewCell) {
    viewModel.archiveStory(byId: cell.storyId)
  }
  func sendCellToInbox(delegatedFrom cell: StoryListTableViewCell) {
    viewModel.unArchiveStory(byId: cell.storyId)
  }
}

extension StoryListTableViewController: ReplyCellDelegate {
  func reply(delegatedFrom cell: ReplyCell) {
    if let storyId = cell.storyId {
      viewModel.setReplyId(storyId: storyId)
      parent?.performSegue(withIdentifier: "ShowCamera", sender: nil)
    }
  }
}

extension StoryListTableViewController: StoryLayoutDelegate {
  func collectionView(_ collectionView: UICollectionView,
                      widthForCellAtIndexPath indexPath: IndexPath) -> CGFloat {
    if (indexPath.item == collectionView.numberOfItems(inSection: 0) - 1) {
      return CGFloat(70)
    } else {
      return CGFloat(147)
    }
  }
}


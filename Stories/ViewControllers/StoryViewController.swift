//
//  StoryViewController.swift
//  Stories
//
//  Created by Chris on 11/29/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import UIKit

class StoryViewController: UIViewController {
  var viewModel: StoryViewModel!
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
  @IBOutlet weak var pageView: UIImageView!
  @IBOutlet weak var authorLabel: UILabel!
  @IBOutlet weak var timestampLabel: UILabel!
  
  @IBAction func touchUpLeaveStory(_ sender: Any) {
    leaveStory()
  }
  
  func showPage() {
    guard let page = self.viewModel.currentPageData else {
      print("current page data failed")
      return
    }
    guard let image = page.backgroundImagePNG, let timestamp = page.timeString,
      let authorName = page.authorName else {
        print("not enough page data supplied")
        return
    }
    pageView.image = image
    timestampLabel.text = timestamp
    authorLabel.text = authorName
  }
  
  @objc func leaveStory() {
    performSegue(withIdentifier: "storyUnwind", sender: nil)
  }
  
  @objc func advanceStory() {
    if viewModel.advanceStory() {
      showPage()
    }
  }
  
  @objc func rewindStory() {
    if viewModel.rewindStory() {
      showPage()
    }
  }

  
  override func viewDidLoad() {
    super.viewDidLoad()
    showPage()
    
    let downSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self,
                                                              action: #selector(StoryViewController.leaveStory))
    downSwipeGestureRecognizer.direction = UISwipeGestureRecognizer.Direction.down
    self.view.addGestureRecognizer(downSwipeGestureRecognizer)
    
    let leftSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self,
                                                              action: #selector(StoryViewController.advanceStory))
    leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizer.Direction.left
    self.view.addGestureRecognizer(leftSwipeGestureRecognizer)
    
    let rightSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self,
                                                              action: #selector(StoryViewController.rewindStory))
    rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizer.Direction.right
    self.view.addGestureRecognizer(rightSwipeGestureRecognizer)

    
    // Do any additional setup after loading the view.
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

//
//  CameraViewController.swift
//  Drifter
//
//  Created by Chris on 8/27/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import UIKit
import Photos

class CameraViewController: UIViewController {
  
  //MARK: properties
  @IBOutlet weak var captureButton: UIButton!
  @IBOutlet weak var cameraSwitcher: UIButton!
  @IBOutlet weak var inboxButton: UIButton!
  @IBOutlet weak var capturePreview: UIView!
  
  var viewModel: CameraViewModel!

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
      if self.viewModel.isReplying() {
        do {
          try self.viewModel.addReply(backgroundImagePNG: imagePNG)
        } catch {
          print(error)
        }
      } else {
        self.viewModel.createSinglePageStory(backgroundImagePNG: imagePNG)
      }
      self.performSegue(withIdentifier: "CameraToStoryList", sender: nil)
    })
  }
  
  @IBAction func showInbox(_ sender: Any) {
    self.performSegue(withIdentifier: "CameraToStoryList", sender: nil)
  }
    
  //MARK: navigation
  
  //MARK: lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    captureButton.layer.cornerRadius = 16
    captureButton.layer.borderColor = UIColor.white.cgColor
    captureButton.layer.borderWidth = 2.0
    
    cameraSwitcher.layer.cornerRadius = 4
    cameraSwitcher.layer.borderColor = UIColor.white.cgColor
    cameraSwitcher.layer.borderWidth = 0.5

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
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
}


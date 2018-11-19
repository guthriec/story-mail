//
//  SlideDownSegue.swift
//  Stories
//
//  Created by Chris on 9/16/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import UIKit

class SlideUpSegueUnwind: UIStoryboardSegue {
  
  override func perform() {
    let bottomView = self.source.view!
    let topView = self.destination.view!
    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height
    
    topView.frame = CGRect(x: 0, y: -screenHeight, width: screenWidth, height: screenHeight)
    
    let window = UIApplication.shared.keyWindow
    window?.addSubview(topView)

    UIView.animate(withDuration: 0.6, animations: {() -> Void in
      bottomView.frame = bottomView.frame.offsetBy(dx: 0.0, dy: screenHeight)
      topView.frame = topView.frame.offsetBy(dx: 0.0, dy: screenHeight)
    }, completion: {(success) -> Void in
      self.source.dismiss(animated: false, completion: nil)
    })
  }
}

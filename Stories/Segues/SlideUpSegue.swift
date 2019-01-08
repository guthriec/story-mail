//
//  SlideDownSegueUnwind.swift
//  Stories
//
//  Created by Chris on 9/17/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import UIKit

class SlideUpSegue: UIStoryboardSegue {
  override func perform() {
    let topView = self.source.view!
    let bottomView = self.destination.view!
    
    let screenHeight = UIScreen.main.bounds.size.height
    let screenWidth = UIScreen.main.bounds.size.width
    
    bottomView.frame = CGRect(x: 0, y: screenHeight, width: screenWidth, height: screenHeight)
    
    let window = UIApplication.shared.keyWindow
    window?.addSubview(bottomView)
    
    UIView.animate(withDuration: 0.6, animations: {() -> Void in
      bottomView.frame = bottomView.frame.offsetBy(dx: 0, dy: -screenHeight)
      topView.frame = topView.frame.offsetBy(dx: 0, dy: -screenHeight)
    }, completion: ({success -> Void in
      self.source.present(self.destination, animated: false, completion: nil)
    }))
  }
}

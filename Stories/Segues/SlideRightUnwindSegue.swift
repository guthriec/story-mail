//
//  SlideRightUnwindSegue.swift
//  Stories
//
//  Created by Chris on 11/1/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import UIKit

class SlideRightUnwindSegue: UIStoryboardSegue {
  override func perform() {
    let rightView = self.source.view!
    let leftView = self.destination.view!
    
    let screenHeight = UIScreen.main.bounds.size.height
    let screenWidth = UIScreen.main.bounds.size.width
    
    leftView.frame = CGRect(x: -screenWidth, y: 0, width: screenWidth, height: screenHeight)
    
    let window = UIApplication.shared.keyWindow
    window?.addSubview(leftView)
    
    UIView.animate(withDuration: 0.6, animations: {() -> Void in
      rightView.frame = rightView.frame.offsetBy(dx: screenWidth, dy: 0)
      leftView.frame = leftView.frame.offsetBy(dx: screenWidth, dy: 0)
    }, completion: ({success -> Void in
      self.source.dismiss(animated: false, completion: nil)
    }))
  }
}

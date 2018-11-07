//
//  SlideLeftSegue.swift
//  Drifter
//
//  Created by Chris on 11/5/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import UIKit

class SlideLeftSegue: UIStoryboardSegue {
  override func perform() {
    let rightView = self.source.view!
    let leftView = self.destination.view!
    
    let screenHeight = UIScreen.main.bounds.size.height
    let screenWidth = UIScreen.main.bounds.size.width
    
    leftView.frame = CGRect(x: -screenWidth, y: 0, width: screenWidth, height: screenHeight)
    
    let window = UIApplication.shared.keyWindow
    window?.addSubview(leftView)
    
    UIView.animate(withDuration: 0.6, animations: {() -> Void in
      leftView.frame = leftView.frame.offsetBy(dx: screenWidth, dy: 0)
      rightView.frame = rightView.frame.offsetBy(dx: screenWidth, dy: 0)
    }, completion: ({success -> Void in
      self.source.present(self.destination, animated: false, completion: nil)
    }))
  }
}

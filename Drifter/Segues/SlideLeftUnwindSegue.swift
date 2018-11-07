//
//  SlideLeftUnwindSegue.swift
//  Drifter
//
//  Created by Chris on 11/5/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import UIKit

class SlideLeftUnwindSegue: UIStoryboardSegue {
  override func perform() {
    let leftView = self.source.view!
    let rightView = self.destination.view!
    
    let screenHeight = UIScreen.main.bounds.size.height
    let screenWidth = UIScreen.main.bounds.size.width
    
    rightView.frame = CGRect(x: screenWidth, y: 0, width: screenWidth, height: screenHeight)
    
    let window = UIApplication.shared.keyWindow
    window?.addSubview(rightView)
    
    UIView.animate(withDuration: 0.6, animations: {() -> Void in
      rightView.frame = rightView.frame.offsetBy(dx: -screenWidth, dy: 0)
      leftView.frame = leftView.frame.offsetBy(dx: -screenWidth, dy: 0)
    }, completion: ({success -> Void in
      self.source.dismiss(animated: false, completion: nil)
    }))
  }
}

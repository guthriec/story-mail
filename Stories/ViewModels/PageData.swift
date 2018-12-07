//
//  PageData.swift
//  Stories
//
//  Created by Chris on 11/29/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import Foundation
import UIKit

class PageData {
  var backgroundImagePNG: UIImage?
  var timeString: String?
  var authorName: String?
  
  init(fromManaged page: PageMO, activeUsername: String?) {
    let dateFormatter = DateFormatter()
    let date = page.timestamp! as Date
    var timeString = ""
    if Calendar.current.isDateInToday(date) {
      dateFormatter.dateFormat = "h:mm a"
      timeString = dateFormatter.string(from: date)
    } else if Calendar.current.isDateInYesterday(date) {
      timeString = "Yesterday"
    } else {
      dateFormatter.dateFormat = "MM/dd/YY"
      timeString = dateFormatter.string(from: date)
    }
    self.timeString = timeString
    
    if let backgroundImage = page.getBackgroundImage() {
      self.backgroundImagePNG = backgroundImage
    }
    
    if let pageAuthor = page.authorName() {
      var authorText = pageAuthor
      if authorText == activeUsername {
        authorText = "You"
      }
      self.authorName = authorText
    }
  }
}

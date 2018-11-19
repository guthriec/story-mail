//
//  InboxStoryLayout.swift
//  Stories
//
//  Created by Chris on 9/21/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//

import UIKit

protocol StoryLayoutDelegate: class {
  func collectionView(_ collectionView: UICollectionView,
                      widthForCellAtIndexPath indexPath: IndexPath) -> CGFloat
}

class StoryLayout: UICollectionViewLayout {
  weak var delegate: StoryLayoutDelegate!
  
  var cache = [UICollectionViewLayoutAttributes]()
  
  let contentHeight: CGFloat = 252
  let cellSpacing: CGFloat = 10
  var contentWidth: CGFloat = 0
  
  override var collectionViewContentSize: CGSize {
    return CGSize(width: contentWidth, height: contentHeight)
  }
  
  override func prepare() {
    cache = Array<UICollectionViewLayoutAttributes>()
    var currWidth: CGFloat = cellSpacing
    guard let collectionView = self.collectionView else {
      return
    }
    let numItems = collectionView.numberOfItems(inSection: 0)
    for itemIndex in 0 ..< numItems {
      let indexPath = IndexPath(item: itemIndex, section: 0)
      let itemWidth = delegate.collectionView(collectionView, widthForCellAtIndexPath: indexPath)
      
      let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
      attributes.frame = CGRect(x: currWidth, y: CGFloat(0), width: itemWidth,
                                height: contentHeight)
      cache.append(attributes)
      currWidth += itemWidth
      currWidth += cellSpacing
    }
    contentWidth = currWidth
  }
  
  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()
    for attributes in cache {
      if attributes.frame.intersects(rect) {
        visibleLayoutAttributes.append(attributes)
      }
    }
    return visibleLayoutAttributes
  }
  
  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    //print("calling layoutAttributesForItem at ", indexPath, " with item index ", indexPath.item)
    return cache[indexPath.item]
  }
}

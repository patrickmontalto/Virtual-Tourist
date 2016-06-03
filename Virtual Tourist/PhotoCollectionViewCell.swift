//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Patrick Montalto on 5/31/16.
//  Copyright © 2016 swift. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {

    var imageName: String = ""
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        
//        if imageView.image == nil {
//            activityIndicator.startAnimating()
//        }
//    }
    
}

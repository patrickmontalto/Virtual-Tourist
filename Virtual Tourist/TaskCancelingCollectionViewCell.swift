//
//  TaskCancelingCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Patrick Montalto on 5/31/16.
//  Copyright © 2016 swift. All rights reserved.
//

import UIKit

class TaskCancelingCollectionViewCell: UICollectionViewCell {
    
    // This property uses a property observer. Any time it's
    // value is set, it cancels the previous NSURLSessionTask
    
    var imageName: String = ""
    
    @IBOutlet var imageView: UIImageView!
    
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}

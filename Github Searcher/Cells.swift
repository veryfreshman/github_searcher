//
//  Cells.swift
//  Github Searcher
//
//  Created by Ivan Komar on 9/6/19.
//  Copyright © 2019 Ivan Komar. All rights reserved.
//

import UIKit

class UserSearchCell : UITableViewCell {
    
    @IBOutlet var avatar:UIImageView!
    @IBOutlet var username:UILabel!
    @IBOutlet var repos:UILabel!
    
    func setImage(_ image:UIImage) {
        avatar.image = image
    }
    
}

class RepoSearchCell : UITableViewCell {
    
    @IBOutlet var stars:UILabel!
    @IBOutlet var forks:UILabel!
    @IBOutlet var username:UILabel!
    
}

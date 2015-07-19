//
//  GroupCell.swift
//  Eventory
//
//  Created by Imran Ahmed on 18/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit

class GroupCell: UITableViewCell {
    @IBOutlet weak var memberlabel: UILabel!
    @IBOutlet weak var grouplabel: UILabel!
    var groupimage: UIImageView = UIImageView(frame: CGRectMake(15, 10, 50, 50));
    var memberlist:String!
    override func awakeFromNib() {
        super.awakeFromNib()
        groupimage.layer.masksToBounds = true;
        groupimage.layer.cornerRadius = 25;
        self.addSubview(groupimage);
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

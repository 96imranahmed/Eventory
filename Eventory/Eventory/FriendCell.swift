//
//  FriendCell.swift
//  Eventory
//
//  Created by Imran Ahmed on 15/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit

class FriendCell: UITableViewCell {
    @IBOutlet weak var friendlabel: UILabel!
    var friendimage: UIImageView = UIImageView(frame: CGRectMake(15, 10, 50, 50));
    var profid:String!
    override func awakeFromNib() {
        super.awakeFromNib()
        friendimage.layer.masksToBounds = true;
        friendimage.layer.cornerRadius = 25;
        self.addSubview(friendimage);
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

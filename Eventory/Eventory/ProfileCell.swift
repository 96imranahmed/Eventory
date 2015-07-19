//
//  ProfileCell.swift
//  Eventory
//
//  Created by Imran Ahmed on 13/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit

class ProfileCell: UITableViewCell {
    @IBOutlet weak var StatusLabel: UILabel!
    var OfflineProfilePicture:UIImageView = UIImageView(frame: CGRectMake(80, 34, 80, 80));
    var LoginButton: FBSDKLoginButton = FBSDKLoginButton(frame: CGRectMake(200, 122, 200, 50))
    override func awakeFromNib() {
        super.awakeFromNib()
        if (Reachability.isConnectedToNetwork()) {
            self.StatusLabel.text = "Logged in as " + Globals.currentprofile!.name!;
        } else {
            self.StatusLabel.text = "Logged in offline as " + Globals.currentprofile!.name!;
        }
        OfflineProfilePicture.layer.masksToBounds = true;
        OfflineProfilePicture.layer.cornerRadius = 40;
        self.addSubview(OfflineProfilePicture);
        self.addSubview(LoginButton)
        // Initialization code
    }


}

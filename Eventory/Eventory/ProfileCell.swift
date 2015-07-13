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
    var ProfilePicture:FBSDKProfilePictureView = FBSDKProfilePictureView(frame: CGRectMake(80, 34, 150, 150));
    var LoginButton: FBSDKLoginButton = FBSDKLoginButton(frame: CGRectMake(200, 192, 200, 50))
    override func awakeFromNib() {
        super.awakeFromNib()
        self.StatusLabel.text = "Logged in as " + Globals.currentprofile!.name!;
        ProfilePicture.layer.masksToBounds = true;
        ProfilePicture.layer.cornerRadius = 75;
        self.addSubview(ProfilePicture)
        self.addSubview(LoginButton)
        // Initialization code
    }


}

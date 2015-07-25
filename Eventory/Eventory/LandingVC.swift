//
//  LandingVC.swift
//  
//
//  Created by Imran Ahmed on 12/07/2015.
//
//

import UIKit
import CoreData

class LandingVC: UIViewController {
    @IBOutlet weak var navpic: UIBarButtonItem!
    @IBOutlet weak var navprofilelabel: UILabel!
    @IBOutlet weak var navtitle: UIView!
  var picbutton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton;
    override func viewDidLoad() {
        super.viewDidLoad()
        //Create button
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "PPUpdated", name: "PPUpdated", object: nil);
        let image = Globals.currentprofile?.imagedata
        picbutton.frame = CGRectMake(0, 0, 28, 28);
        if (image?.length == 0) {
            picbutton.setImage(UIImage(named: "unkownprofile.png"), forState: UIControlState.Normal)
        } else {
            picbutton.setImage(UIImage(data: Globals.currentprofile!.imagedata!)!, forState: UIControlState.Normal)
        }
        picbutton.layer.masksToBounds = true;
        picbutton.layer.cornerRadius = picbutton.frame.height/2;
        picbutton.addTarget(self, action: Selector("ProfileViewLoad:"), forControlEvents: UIControlEvents.TouchDown)
        var barbutton:UIBarButtonItem = UIBarButtonItem(customView: picbutton);
        self.navigationItem.rightBarButtonItem = barbutton;
        navprofilelabel.text = getTitle() +  ", " + getFirstName(FBSDKProfile.currentProfile().name +  "!");
    }
    func PPUpdated () {
        picbutton.setImage(UIImage(data: Globals.currentprofile!.imagedata!)!, forState: UIControlState.Normal)
    }
    func ProfileViewLoad (sender: UIButton!) {
        dispatch_async(dispatch_get_main_queue(), {
            self.performSegueWithIdentifier("LandingtoLogout", sender: nil);
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getFirstName(name: String) -> String {
        var fullNameArr = split(name) {$0 == " "}
        return fullNameArr[0]
    }

    func getTitle() -> String {
        var now:NSDate = NSDate();
        var possiblelists:[String] = ["Hi", "Howdy", "Hey"];
        let cal = NSCalendar.currentCalendar();
        let comps = cal.components(NSCalendarUnit.CalendarUnitHour, fromDate: now);
        let hour = comps.hour;
        switch hour {
        case 0 ... 12:
            possiblelists.append("Morning");
            possiblelists.append("Good morning");
        case 13 ... 17:
            possiblelists.append("Afternoon");
            possiblelists.append("Good afternoon");
        case 17 ... 24:
            possiblelists.append("Evening");
            possiblelists.append("Good evening");
        default:
            NSLog("Time error!");
        }
        var random = Int(arc4random_uniform(UInt32(possiblelists.count)))
        return possiblelists[random];
    }
 
}

//
//  LandingVC.swift
//  
//
//  Created by Imran Ahmed on 12/07/2015.
//
//

import UIKit
import CoreData

class LandingVC: UIViewController, UIGestureRecognizerDelegate {
    var picbutton: UIImageView! = UIImageView(frame: CGRectMake(0, 1, 30, 30));
    var navprofilelabel: UILabel! = UILabel(frame: CGRectMake(0, 6, 214, 20));
    var navtitle: UIView! = UIView(frame: CGRectMake(0, 0, 0, 0));
    override func viewDidLoad() {
        super.viewDidLoad()
        //Create button
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "PPUpdated", name: "PPUpdated", object: nil);
        let image = Globals.currentprofile?.imagedata
        if (image?.length == 0) {
            picbutton.image = UIImage(named: "unkownprofile.png")
        } else {
            picbutton.image = UIImage(data: Globals.currentprofile!.imagedata!)
        }
        picbutton.layer.masksToBounds = true;
        picbutton.layer.cornerRadius = picbutton.frame.height/2;
        let tap = UITapGestureRecognizer(target: self, action: Selector("ProfileViewLoad:"))
        tap.delegate = self
        navtitle.addGestureRecognizer(tap)
        if let name = Globals.currentprofile?.name {
        navprofilelabel.text = getTitle() +  ", " + getFirstName(name) +  "!";
        } else {
            NSLog("Forced logout - Profile error?");
            dispatch_async(dispatch_get_main_queue(), {
                self.performSegueWithIdentifier("LandingtoLogout", sender: nil);
            })
        }
        let reqsize = navprofilelabel.sizeThatFits(CGSizeMake(self.navtitle.frame.size.width, 30))
        navprofilelabel.frame.size = reqsize;
        picbutton.frame = CGRectMake((reqsize.width + 8), 1, 30, 30);
        navtitle.addSubview(picbutton);
        navtitle.addSubview(navprofilelabel);
        navtitle.frame = CGRectMake(0, 0, navprofilelabel.frame.size.width + 38, 33);
        navtitle.center = CGPointMake(self.view.center.x, 16.5);
        navtitle.autoresizesSubviews = false;
        self.navigationItem.titleView = navtitle;
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: imageResize(UIImage(named: "bell.png")!, sizeChange: CGSizeMake(25, 25)), style: UIBarButtonItemStyle.Plain, target: self, action: "NotificationsDidTap:");
        let frame = navtitle.frame;
        let center = navtitle.center;
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true);
    }
    func imageResize (imageObj:UIImage, sizeChange:CGSize)-> UIImage{
        let hasAlpha = true;
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
    }
    func PPUpdated () {
        picbutton.image = UIImage(data: Globals.currentprofile!.imagedata!)
    }
    func ProfileViewLoad (sender: UITapGestureRecognizer) {
        dispatch_async(dispatch_get_main_queue(), {
            self.performSegueWithIdentifier("LandingtoLogout", sender: nil);
        })
    }
    func NotificationsDidTap(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue(), {
            self.performSegueWithIdentifier("LandingtoNotifications", sender: nil);
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
        var possiblelists:[String] = ["Hi", "Howdy", "Hey", "Hello", "Heya", "Greetings"];
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

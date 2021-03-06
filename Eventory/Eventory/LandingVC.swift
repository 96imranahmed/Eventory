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
    @IBOutlet var hub: RKNotificationHub!;
    var picbutton: UIImageView! = UIImageView(frame: CGRectMake(0, 1, 30, 30));
    var navprofilelabel: UILabel! = UILabel(frame: CGRectMake(0, 6, 214, 20));
    var navtitle: UIView! = UIView(frame: CGRectMake(0, 0, 0, 0));
    override func viewDidLoad() {
        super.viewDidLoad()
        //Create notification page
        let nview: UIView = UIView(frame: CGRectMake(0, 0, 25, 25));
        let nimage: UIButton = UIButton(frame: CGRectMake(0, 0, 25, 25));
        nimage.setBackgroundImage(imageResize(UIImage(named: "bell.png")!, sizeChange: CGSizeMake(25, 25)).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), forState: UIControlState.Normal);
        nimage.tintColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1);
        nimage.addTarget(self, action: "NotificationsDidTap:", forControlEvents: UIControlEvents.TouchDown);
        nview.addSubview(nimage);
        dispatch_async(dispatch_get_main_queue(), {
            self.hub = RKNotificationHub(view: nview);
            self.hub.moveCircleByX(0, y: -5);
            self.hub.scaleCircleSizeBy(0.6);
        })
        let notificationbutton:UIBarButtonItem = UIBarButtonItem(customView: nview);
        self.navigationItem.rightBarButtonItem = notificationbutton;
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "PPUpdated", name: "PPUpdated", object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshnotifications:", name: "Eventory_Notifications_Done", object: nil)
        //Load user profile
        Globals.currentprofile = Profile.fetchProfileforID(FBSDKAccessToken.currentAccessToken().userID);
        let image = Globals.currentprofile?.imagedata
        if (Globals.currentprofile?.name == "") {
            picbutton.image = UIImage(named: "unkownprofile.png");
            navprofilelabel.text = "Unknown";
            NSLog("Forced logout - Profile error?");
            dispatch_async(dispatch_get_main_queue(), {
                self.performSegueWithIdentifier("LandingtoLogout", sender: nil);
            })
        } else {
            if ((image) != nil) {
                picbutton.image = UIImage(data: Globals.currentprofile!.imagedata!)
            } else {
                picbutton.image = UIImage(named: "unkownprofile.png")
            }
            if let name = Globals.currentprofile?.name {
                navprofilelabel.text = getTitle() +  ", " + getFirstName(name) +  "!";
            }
        }
        picbutton.layer.masksToBounds = true;
        picbutton.layer.cornerRadius = picbutton.frame.height/2;
        let tap = UITapGestureRecognizer(target: self, action: Selector("ProfileViewLoad:"))
        tap.delegate = self
        navtitle.addGestureRecognizer(tap)
        let reqsize = navprofilelabel.sizeThatFits(CGSizeMake(self.navtitle.frame.size.width, 30))
        navprofilelabel.frame.size = reqsize;
        picbutton.frame = CGRectMake((reqsize.width + 8), 1, 30, 30);
        navtitle.addSubview(picbutton);
        navtitle.addSubview(navprofilelabel);
        navtitle.frame = CGRectMake(0, 0, navprofilelabel.frame.size.width + 38, 33);
        navtitle.center = CGPointMake(self.view.center.x, 16.5);
        navtitle.autoresizesSubviews = false;
        self.navigationItem.titleView = navtitle;
        //self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: imageResize(UIImage(named: "bell.png")!, sizeChange: CGSizeMake(25, 25)), style: UIBarButtonItemStyle.Plain, target: self, action: "NotificationsDidTap:");
        _ = navtitle.frame;
        _ = navtitle.center;
        _ = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "animateNotifications", userInfo: nil, repeats: true);
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true);
if Globals.unreadnotificationcount > 0 {
            self.hub.decrementBy(self.hub.count)
            self.hub.incrementBy(UInt(Globals.unreadnotificationcount));
            self.hub.pop();
        } else {
            self.hub.decrementBy(self.hub.count)
            self.hub.pop();
        }
        if Globals.profloaded {
        Notification.getNotifications(Constants.notificationloadlimit, page: 0);
        }
    }
    override func viewWillAppear(animated: Bool) {
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imageResize (imageObj:UIImage, sizeChange:CGSize)-> UIImage{
        let hasAlpha = true;
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
    }
    
    //MARK: Refresh functions
    func animateNotifications() {
        //NSLog("Refreshed with count: " + hub.count.description)
        dispatch_async(dispatch_get_main_queue(), {
            self.hub.bump();
        })
    }
    func PPUpdated () {
        picbutton.image = UIImage(data: Globals.currentprofile!.imagedata!)
    }
    func refreshnotifications(notification: NSNotification) {
        let count = Globals.unreadnotificationcount;
        dispatch_async(dispatch_get_main_queue(), {
            self.hub.decrementBy(self.hub.count)
            self.hub.incrementBy(UInt(count));
            self.hub.pop();
        })
    }
    
    //MARK: Segue Links
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
    
    
    //MARK: String functions
    func getFirstName(name: String) -> String {
        var fullNameArr = name.characters.split {$0 == " "}.map { String($0) }
        return fullNameArr[0]
    }
    
    func getTitle() -> String {
        let name = getFirstName((Globals.currentprofile?.name)!);
        var short = true;
        if name.characters.count > 8 {
            short = false
        }
        let now:NSDate = NSDate();
        var possiblelists:[String] = ["Hi", "Howdy", "Hey", "Hello", "Heya", "Greetings"];
        let cal = NSCalendar.currentCalendar();
        let comps = cal.components(NSCalendarUnit.Hour, fromDate: now);
        let hour = comps.hour;
        switch hour {
        case 0 ... 12:
            possiblelists.append("Morning");
            if (short) {
                possiblelists.append("Good morning");
            }
        case 13 ... 17:
            possiblelists.append("Afternoon");
            if (short) {
                possiblelists.append("Good afternoon");
            }
        case 17 ... 24:
            possiblelists.append("Evening");
            if (short) {
                possiblelists.append("Good evening");
            }
        default:
            NSLog("Time error!");
        }
        let random = Int(arc4random_uniform(UInt32(possiblelists.count)))
        return possiblelists[random];
    }
    
}

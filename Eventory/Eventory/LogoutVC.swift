//
//  LogoutVC.swift
//
//
//  Created by Imran Ahmed on 13/07/2015.
//
//

import UIKit
import CoreData

class LogoutVC: UIViewController, UITableViewDelegate, UITableViewDataSource, FBSDKLoginButtonDelegate {
    @IBOutlet weak var settingstable: UITableView!
    let appName: String! = "Eventory";
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Profile & Settings";
        settingstable.allowsSelection = false;
        settingstable.dataSource = self;
        settingstable.delegate = self;
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        let errordelete = Locksmith.deleteDataForUserAccount(self.appName);
        ClearProfiles();
        self.performSegueWithIdentifier("LogouttoLogin", sender: self);
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {}
    
    func ClearProfiles () {
        //Clears profiles only
        let fetchRequest = NSFetchRequest(entityName: "Profile")
        let fetchResults = (self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile])!
        for (var i = 0; i < fetchResults.count ; i++) {
            self.managedObjectContext?.deleteObject(fetchResults[i]);
        }
    }
    //Table View methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "Profile";
        } else {
            return nil;
        }
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 1;
        } else {
            return 0;
        }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath == NSIndexPath(forRow: 0, inSection: 0)) {
            var cell = tableView.dequeueReusableCellWithIdentifier("Profile") as! ProfileCell;
            //Correct ProfilePicture view
            cell.ProfilePicture.frame = CGRectMake(self.view.center.x - 75,cell.ProfilePicture.frame.origin.y , 150, 150)
            cell.LoginButton.frame = CGRectMake(self.view.center.x - 100,192 , 200 , 50)
            cell.LoginButton.delegate = self;
            return cell;
        } else {
            return UITableViewCell();
        }
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //So far add nothing (allows selection = false)
    }
    
    
}

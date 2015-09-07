//
//  TodayViewController.swift
//  VT Widget
//
//  Created by Connor Wybranowski on 9/4/15.
//  Copyright (c) 2015 Wybro. All rights reserved.
//

import UIKit
import NotificationCenter
//import JBChartView

class TodayViewController: UIViewController, NCWidgetProviding, JBLineChartViewDelegate, JBLineChartViewDataSource {
    
    let customGreen = UIColor(red: 19/255, green: 183/255, blue: 121/255, alpha: 1)
    let customHighlightGreen = UIColor(red: 19/255, green: 238/255, blue: 121/255, alpha: 1)
    let customRed = UIColor(red: 254/255, green: 20/255, blue: 37/255, alpha: 1)
//    let data = [1000, 1250, 1850, 1430, 2000, 7000, 4500, 4700, 5200, 6300]
    
    var dataPoints: [Int] = [Int]()
    var cachedUser: [String:AnyObject] = [String:AnyObject]()
    
    @IBOutlet var lineChartView: JBLineChartView!
    @IBOutlet var followerLabel: UILabel!
    @IBOutlet var newFollowersLabel: UILabel!
    @IBOutlet var avatarPicImageView: UIImageView!
    @IBOutlet var warningLabel: UILabel!
    @IBOutlet var followersStaticLabel: UILabel!
    @IBOutlet var todayStaticLabel: UILabel!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
//        let lineChartView = JBLineChartView()
        lineChartView.dataSource = self
        lineChartView.delegate = self
        lineChartView.backgroundColor = UIColor.clearColor()
//        lineChartView.frame = CGRectMake(0, self.lineChartView.bounds.height - self.lineChartView.bounds.height * 0.25, self.view.bounds.width, self.lineChartView.bounds.height)
        lineChartView.showsLineSelection = false
        lineChartView.showsVerticalSelection = false
        lineChartView.reloadData()
//        self.view.addSubview(lineChartView)
        println("Launched")
        
        self.avatarPicImageView.layer.cornerRadius = self.avatarPicImageView.frame.size.width / 2
        self.avatarPicImageView.clipsToBounds = true
        
//        fetchNewData()
        
//        println("viewdidload")
    }
    
    override func viewDidAppear(animated: Bool) {
//        fetchNewData(self.getUserSearchSettings())
    }
    
    override func viewWillAppear(animated: Bool) {
        // reload data (if any) from cached state
        loadUserFromCache()
    }
    
    override func viewWillDisappear(animated: Bool) {
        // save current data (if any) to cached state
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        fetchNewData(self.getUserSearchSettings())
        completionHandler(NCUpdateResult.NewData)
    }
    
    func numberOfLinesInLineChartView(lineChartView: JBLineChartView!) -> UInt {
        return 1
    }
    
    func lineChartView(lineChartView: JBLineChartView!, numberOfVerticalValuesAtLineIndex lineIndex: UInt) -> UInt {
        return UInt(dataPoints.count)
    }
    
    func lineChartView(lineChartView: JBLineChartView!, verticalValueForHorizontalIndex horizontalIndex: UInt, atLineIndex lineIndex: UInt) -> CGFloat {
        return CGFloat(dataPoints[Int(horizontalIndex)])
    }
    
    func lineChartView(lineChartView: JBLineChartView!, verticalSelectionColorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
        return UIColor.redColor()
    }
    
    func lineChartView(lineChartView: JBLineChartView!, colorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
        return customGreen
    }
    
    func lineChartView(lineChartView: JBLineChartView!, widthForLineAtLineIndex lineIndex: UInt) -> CGFloat {
        return 3
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
    func loadUserFromCache() {
        let sharedDefaults = NSUserDefaults(suiteName: "group.com.Wybro.Vino-VineTracker")
        if let loadedUser = sharedDefaults?.objectForKey("cachedUser") as? [String: AnyObject] {
            println("Cached user found - loading from cached data")
            var cachedFollowers = loadedUser["currentFollowers"] as! Int
            var cachedNewFollowers = loadedUser["newFollowers"] as! Int
            var cachedAvatarPicData = loadedUser["avatarPic"] as! NSData
            var cachedAvatarImage = UIImage(data: cachedAvatarPicData)! as UIImage
            var cachedDataPoints = loadedUser["dataPoints"] as! [Int]
            updateLabels(cachedFollowers, newFollowers: cachedNewFollowers)
            updateAvatarPic(cachedAvatarImage)
            updateGraph(cachedDataPoints)
        }
        else {
            println("No cached user found")
        }
    }
    
    func getUserSearchSettings() -> String? {
        let sharedDefaults = NSUserDefaults(suiteName: "group.com.Wybro.Vino-VineTracker")
        var returnString = sharedDefaults?.objectForKey("userSearchString") as? String
        if returnString == nil {
            warningLabel.hidden = false
            followerLabel.hidden = true
            followersStaticLabel.hidden = true
            newFollowersLabel.hidden = true
            todayStaticLabel.hidden = true
        }
        else {
           warningLabel.hidden = true
            followerLabel.hidden = false
            followersStaticLabel.hidden = false
            newFollowersLabel.hidden = false
            todayStaticLabel.hidden = false
        }
//        println(returnString)
        return returnString
    }
    
    func fetchNewData(searchString: String?) {
        println("Fetching data")
        //        VineConnection.getUserDataForID(bcUserId, completionHandler: { (vineUser:VineUser) -> () in
        if (searchString != nil) {
            if !searchString!.isEmpty {
//                self.updateUserSearchSettings(searchString!)
                VineConnection.getUserDataForName(searchString!, completionHandler: { (vineUser:VineUser) -> () in
                    // Update settings
                    //                self.updateUserSearchSettings(searchString!)
                    
                    //            println(vineUser.username)
                    //            println(vineUser.followerCount)
                    //            println(vineUser.loopCount)
                    
                    let sharedDefaults = NSUserDefaults(suiteName: "group.com.Wybro.Vino-VineTracker")
                    
                    var newFollowers = 0
                    
                    if let foundUser = sharedDefaults?.objectForKey("\(vineUser.userId)") as? [String:AnyObject] {
                        //                println("User found!")
                        //                println(foundUser)
                        
                        var newDataPoints = foundUser["dataPoints"] as! [Int]
                        newDataPoints.append(vineUser.followerCount)
                        if newDataPoints.endIndex >= 20 {
                            newDataPoints.removeAtIndex(0)
                        }
                        self.updateGraph(newDataPoints)

                        let calendar = NSCalendar.currentCalendar()
                        var startingFollowers = foundUser["newFollowersData"]!["startingFollowers"] as! Int
                        var newFollowersFromPreviousDate = foundUser["newFollowersData"]!["newFollowersFromPreviousDate"] as! Int
                        
                        newFollowers = vineUser.followerCount - startingFollowers
                        
                        if let savedDate = foundUser["newFollowersData"]!["date"] as? NSDate {
                            // Saved date is not in today - change startingFollowers
                            if !calendar.isDateInToday(savedDate) {
                                startingFollowers = vineUser.followerCount
                                newFollowersFromPreviousDate = newFollowers
                            }
                        }
                        
                        var now = NSDate()
                        var user = ["username": vineUser.username, "userId": vineUser.userId, "followerCount": vineUser.followerCount, "loopCount": vineUser.loopCount, "dataPoints":newDataPoints, "newFollowersData": ["date": now, "startingFollowers": startingFollowers, "newFollowersFromPreviousDate": newFollowersFromPreviousDate]]
                        //                println(user)
                        sharedDefaults?.setObject(user, forKey: "\(vineUser.userId)")
                        sharedDefaults?.synchronize()
                        
                        // cache user
                        self.saveUserToCache(vineUser.username, avatarPic: vineUser.avatarPic, currentFollowers: vineUser.followerCount, newFollowers: newFollowers, dataPoints: newDataPoints)
                        
                        println("Saved user")
//                        println(user)
                        
                        // cache data
//                        if let userToSave = user as? [String: AnyObject] {
//                            println("caching user")
//                            self.cachedUser = userToSave
//                            //                            println(self.cachedUser)
//                        }
                    }
                    else {
                        println("User not found -- creating new record")
                        var now = NSDate()
                        var user = ["username": vineUser.username, "userId": vineUser.userId, "followerCount": vineUser.followerCount, "loopCount": vineUser.loopCount, "dataPoints":[vineUser.followerCount], "newFollowersData": ["date": now, "startingFollowers": vineUser.followerCount, "newFollowersFromPreviousDate": newFollowers]]
                        sharedDefaults?.setObject(user, forKey: "\(vineUser.userId)")
                        sharedDefaults?.synchronize()
                        
                        // cache user
                        self.saveUserToCache(vineUser.username, avatarPic: vineUser.avatarPic, currentFollowers: vineUser.followerCount, newFollowers: newFollowers, dataPoints: [vineUser.followerCount])
                        
                        println("New user")
//                        println(user)
                        
                        // cache data
//                        if let userToSave = user as? [String: AnyObject] {
//                            println("caching user")
//                            self.cachedUser = userToSave
//                            //                            println(self.cachedUser)
//                        }
                    }
                    
                    // Use separate UI update function here
                    self.updateLabels(vineUser.followerCount, newFollowers: newFollowers)
                    self.updateAvatarPic(vineUser.avatarPic)
                })
            }
        }

    }
    
    func updateLabels(followers: Int, newFollowers: Int) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            var followersFormatted = NSNumberFormatter.localizedStringFromNumber(followers, numberStyle: NSNumberFormatterStyle.DecimalStyle)
            var newFollowersFormatted = NSNumberFormatter.localizedStringFromNumber(newFollowers, numberStyle: NSNumberFormatterStyle.DecimalStyle)
            
            self.followerLabel.text = followersFormatted
            
            if newFollowers >= 0 {
                self.newFollowersLabel.textColor = self.customHighlightGreen
                self.newFollowersLabel.text = "+\(newFollowersFormatted)"
            }
            else if newFollowers < 0 {
                self.newFollowersLabel.textColor = self.customRed
                self.newFollowersLabel.text = "\(newFollowersFormatted)"
            }
        })
    }
    
    func updateAvatarPic(image: UIImage) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.avatarPicImageView.image = image
        })
    }
    
    func updateGraph(dataPointsArr: [Int]) {
        dataPoints.removeAll(keepCapacity: false)
        println("Updating graph")
        println(dataPointsArr)
        for entry in dataPointsArr {
            dataPoints.append(Int(entry as NSNumber))
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.lineChartView.reloadData()
        })
    }
    
    @IBAction func openApp(sender: UIButton) {
        let url: NSURL? = NSURL(string: "vinoMainApp://")
        
        if let appurl = url {
            self.extensionContext!.openURL(appurl,
                completionHandler: nil)
        }
    }
    
    func saveUserToCache(username: String, avatarPic: UIImage, currentFollowers: Int, newFollowers: Int, dataPoints: [Int]) {
        let sharedDefaults = NSUserDefaults(suiteName: "group.com.Wybro.Vino-VineTracker")
        let imageData: NSData = UIImageJPEGRepresentation(avatarPic, 1)
        let user: [String: AnyObject] = ["username": username, "avatarPic": imageData, "currentFollowers": currentFollowers, "newFollowers": newFollowers, "dataPoints": dataPoints]
        sharedDefaults?.setObject(user, forKey: "cachedUser")
        sharedDefaults?.synchronize()
    }
    
    
}

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
    let customPurple = UIColor(red: 167/255, green: 99/255, blue: 208/255, alpha: 1)
    
    let customGreenBackground = UIColor(red: 19/255, green: 183/255, blue: 121/255, alpha: 1)
    let customPurpleBackground = UIColor(red: 167/255, green: 99/255, blue: 208/255, alpha: 1)
    let customLightPurpleBackground = UIColor(red: 196/255, green: 141/255, blue: 228/255, alpha: 1)
    
    var dataPoints: [Int] = [Int]()
    
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
        
        lineChartView.dataSource = self
        lineChartView.delegate = self
        lineChartView.backgroundColor = UIColor.clearColor()
        lineChartView.showsLineSelection = false
        lineChartView.showsVerticalSelection = false
        lineChartView.reloadData()
        
        println("Launched")
        
        self.avatarPicImageView.layer.cornerRadius = self.avatarPicImageView.frame.size.width / 2
        self.avatarPicImageView.clipsToBounds = true
        
        checkUserSearchSettings()
    }
    
    override func viewDidAppear(animated: Bool) {
        
    }
    
    override func viewWillAppear(animated: Bool) {
        // reload data (if any) from cached state
        checkUserDisplaySetting()
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
        
        fetchNewData(UserDefaultsManager.getUserSearchSettings())
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
        if let displaySetting = UserDefaultsManager.getUserDisplaySetting() as String!{
            if displaySetting == "loopView" {
                return customPurpleBackground
            }
        }
        return customGreenBackground
    }
    
    func lineChartView(lineChartView: JBLineChartView!, widthForLineAtLineIndex lineIndex: UInt) -> CGFloat {
        return 3
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
    func checkUserSearchSettings() {
        if let searchSetting = UserDefaultsManager.getUserSearchSettings() as String! {
            warningLabel.hidden = true
            followerLabel.hidden = false
            followersStaticLabel.hidden = false
            newFollowersLabel.hidden = false
            todayStaticLabel.hidden = false
            
        }
        else {
            warningLabel.hidden = false
            followerLabel.hidden = true
            followersStaticLabel.hidden = true
            newFollowersLabel.hidden = true
            todayStaticLabel.hidden = true
        }
    }
    
    func checkUserDisplaySetting() {
        if let displaySetting = UserDefaultsManager.getUserDisplaySetting() as String! {
            if displaySetting == "followerView" {
                followerViewMode()
            }
            else if displaySetting == "loopView" {
                loopViewMode()
            }
        }
    }
    
    func followerViewMode() {
        println("followerViewMode")
        UserDefaultsManager.updateUserDisplaySetting("followerView")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.followersStaticLabel.text = "followers"
            self.followersStaticLabel.textColor = self.customGreenBackground
            self.followerLabel.textColor = self.customGreenBackground
            UserDefaultsManager.loadUserFromCache({ (savedUser) -> () in
                self.updateLabels(savedUser.followerCount, newFollowers: savedUser.newFollowers)
                self.updateGraph(savedUser.followerDataPoints)
                self.updateAvatarPic(savedUser.avatarPic)
            })
        })
    }
    
    func loopViewMode() {
        println("loopViewMode")
        UserDefaultsManager.updateUserDisplaySetting("loopView")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.followersStaticLabel.text = "loops"
            self.followersStaticLabel.textColor = self.customLightPurpleBackground
            self.followerLabel.textColor = self.customLightPurpleBackground
            UserDefaultsManager.loadUserFromCache({ (savedUser) -> () in
                self.updateLabels(savedUser.loopCount, newFollowers: savedUser.newLoops)
                self.updateGraph(savedUser.loopDataPoints)
                self.updateAvatarPic(savedUser.avatarPic)
            })
        })
    }
    
    func fetchNewData(searchString: String?) {
        println("Fetching data")
        if (searchString != nil) {
            if !searchString!.isEmpty {
                
                //                showActionPopoverView("loading")
                
                VineConnection.getUserDataForName(searchString!, completionHandler: { (vineUser:VineUser, error:String) -> () in
                    
                    if !error.isEmpty {
                        println("error: \(error)")
                        //                        self.stopSpinningAction()
                        //                        self.showActionPopoverView("noUser")
                        return
                    }
                    else {
                        //                        self.hideActionPopoverView()
                        println("search successful - saving search")
                        UserDefaultsManager.updateUserSearchSettings(searchString!)
                    }
                    
                    //                    self.hideUserSearch()
                    
                    // Update settings
                    var foundUser: SavedUser? = nil
                    var newFollowers = 0
                    var newFollowersFromPreviousDate = 0
                    var newLoops = 0
                    var newLoopsFromPreviousDate = 0
                    
                    UserDefaultsManager.getSavedUser("\(vineUser.userId)", completionHandler: { (savedUser) -> () in
                        println("saved user: \(savedUser)")
                        foundUser = savedUser
                    })
                    
                    if foundUser != nil {
                        var followerDataPoints = foundUser!.followerDataPoints
                        followerDataPoints?.append(vineUser.followerCount)
                        if followerDataPoints?.endIndex > 20 {
                            followerDataPoints?.removeAtIndex(0)
                        }
                        
                        var loopDataPoints = foundUser!.loopDataPoints
                        loopDataPoints?.append(vineUser.loopCount)
                        if loopDataPoints?.endIndex > 20 {
                            loopDataPoints?.removeAtIndex(0)
                        }
                        
                        if let displaySetting = UserDefaultsManager.getUserDisplaySetting() as String!{
                            if displaySetting == "followerView" {
                                self.updateGraph(followerDataPoints)
                            }
                            else if displaySetting == "loopView" {
                                self.updateGraph(loopDataPoints)
                            }
                        }
                        
                        let calendar = NSCalendar.currentCalendar()
                        
                        var startingFollowers = foundUser!.startingFollowers
                        var startingLoops = foundUser!.startingLoops
                        newFollowersFromPreviousDate = foundUser!.newFollowersFromPreviousDate!
                        newLoopsFromPreviousDate = foundUser!.newLoopsFromPreviousDate!
                        
                        if !calendar.isDateInToday(foundUser!.date) {
                            
                            // Data is one day old
                            if calendar.isDateInYesterday(foundUser!.date) {
                                // Update newLoops/Follower data
                                newFollowersFromPreviousDate = vineUser.followerCount - startingFollowers
                                newLoopsFromPreviousDate = vineUser.loopCount - startingLoops
                            }
                                // Data is older than one day
                            else {
                                // Reset values to 0
                                newFollowersFromPreviousDate = 0
                                newLoopsFromPreviousDate = 0
                            }
                            
                            // Reset starting values
                            startingFollowers = vineUser.followerCount
                            startingLoops = vineUser.loopCount
                            
                        }
                        
                        newFollowers = vineUser.followerCount - startingFollowers
                        newLoops = vineUser.loopCount - startingLoops
                        
                        var now = NSDate()
                        
                        let userToSave = SavedUser(username: vineUser.username, userId: vineUser.userId, avatarPic: vineUser.avatarPic, followerCount: vineUser.followerCount, newFollowers: newFollowers, followerDataPoints: followerDataPoints, loopCount: vineUser.loopCount, newLoops: newLoops, loopDataPoints: loopDataPoints, date: now, startingFollowers: startingFollowers, newFollowersFromPreviousDate: newFollowersFromPreviousDate, startingLoops: startingLoops, newLoopsFromPreviousDate: newLoopsFromPreviousDate)
                        
                        UserDefaultsManager.saveUser(userToSave, key: "\(vineUser.userId)")
                        UserDefaultsManager.saveUserToCache(userToSave)
                        println("User Found")
                        println(userToSave)
                        
                        
                    }
                    else {
                        println("User not found -- creating new record")
                        var now = NSDate()
                        
                        var newUser = SavedUser(username: vineUser.username, userId: vineUser.userId, avatarPic: vineUser.avatarPic, followerCount: vineUser.followerCount, newFollowers: newFollowersFromPreviousDate, followerDataPoints: [vineUser.followerCount], loopCount: vineUser.loopCount, newLoops: newLoops, loopDataPoints: [vineUser.loopCount], date: now, startingFollowers: vineUser.followerCount, newFollowersFromPreviousDate: newFollowers, startingLoops: vineUser.loopCount, newLoopsFromPreviousDate: newLoops)
                        UserDefaultsManager.saveUser(newUser, key: "\(vineUser.userId)")
                        UserDefaultsManager.saveUserToCache(newUser)
                    }
                    
                    // Use separate UI update function here
                    if let displaySetting = UserDefaultsManager.getUserDisplaySetting() as String!{
                        if displaySetting == "followerView" {
                            self.updateLabels(vineUser.followerCount, newFollowers: newFollowers)
                        }
                        else if displaySetting == "loopView" {
                            self.updateLabels(vineUser.loopCount, newFollowers: newLoops)
                        }
                    }
                    //                    self.updateLabels(vineUser.followerCount, newFollowers: newFollowers)
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
    
}

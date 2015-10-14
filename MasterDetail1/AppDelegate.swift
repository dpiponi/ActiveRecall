//
//  AppDelegate.swift
//  MasterDetail1
//
//  Created by Dan Piponi on 10/1/15.
//  Copyright (c) 2015 Dan Piponi. All rights reserved.
//

import UIKit

// http://stackoverflow.com/questions/14940178/open-with-issue-if-app-is-not-already-open

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    var slideListController: MasterViewController! = nil

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let splitViewController = self.window!.rootViewController as! UISplitViewController
//        splitViewController.presentsWithGesture = true
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController

        let barButton = splitViewController.displayModeButtonItem()
        navigationController.topViewController!.navigationItem.leftBarButtonItem = barButton
        splitViewController.delegate = self
        
        let navController = splitViewController.viewControllers[0] as! UINavigationController
        slideListController = navController.topViewController as! MasterViewController
        slideListController.title = "Slide Decks"
        
        setUpDocumentation()
        return true
    }
    
    func setUpDocumentation() {
        // Set up documentation?
        let path = NSBundle.mainBundle().pathForResource("ActiveRecall", ofType:"pdf")
        let url = NSURL.fileURLWithPath(path!)
        slideListController.setUpSlideDeck(openURL: url, moving:false, addingToList:false)
    }
    
    func splitViewController(svc: UISplitViewController, willHideViewController aViewController: UIViewController, withBarButtonItem barButtonItem: UIBarButtonItem, forPopoverController pc: UIPopoverController) {
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
    }

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        if let secondaryAsNavController = secondaryViewController as? UINavigationController {
            if let topAsDetailController = secondaryAsNavController.topViewController as? SlideDeckController {
                if topAsDetailController.slideRootDir == nil {
                    // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
                    return true
                }
            }
        }
        return false
    }
}


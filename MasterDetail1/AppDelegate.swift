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
        splitViewController.presentsWithGesture = true
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController

        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        splitViewController.delegate = self
        
//        let documentsDirectory = NSFileManager.defaultManager().URLsForDirectory(
//            NSSearchPathDirectory.DocumentDirectory,
//            inDomains: NSSearchPathDomainMask.UserDomainMask)[0]
//        
//        let destDir : NSURL = documentsDirectory.URLByAppendingPathComponent("Decks")
       
        let navController = splitViewController.viewControllers[0] as! UINavigationController
        slideListController = navController.topViewController as! MasterViewController
        
        // Set up documentation?
        let path = NSBundle.mainBundle().pathForResource("ActiveRecall", ofType:"pdf")
        print("path=", path)
        let url = NSURL.fileURLWithPath(path!)
        setUpSlideDeck(openURL: url, moving:false, addingToList:false)
        
        return true
    }
    
    func splitViewController(svc: UISplitViewController, willHideViewController aViewController: UIViewController, withBarButtonItem barButtonItem: UIBarButtonItem, forPopoverController pc: UIPopoverController) {
        print("XXXXXXX")
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
            if let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController {
                if topAsDetailController.slideRootDir == nil {
                    // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
                    return true
                }
            }
        }
        return false
    }

    func setUpSlideDeck(openURL url: NSURL, moving: Bool, addingToList: Bool) {
        let filemgr = NSFileManager.defaultManager()
        let documentsDirectory = filemgr.URLsForDirectory(
            NSSearchPathDirectory.DocumentDirectory,
            inDomains: NSSearchPathDomainMask.UserDomainMask)[0]
        
        
        let destDir : NSURL = documentsDirectory.URLByAppendingPathComponent("Decks")
            .URLByAppendingPathComponent(url.lastPathComponent!)
            .URLByDeletingPathExtension!
        
        
        var updatingDeck : Bool = false
        // Create that directory
        if (filemgr.fileExistsAtPath(destDir.path!)) {
            updatingDeck = true
        } else {
            print("Doesnt exist", destDir)
            do {
                try filemgr.createDirectoryAtPath(destDir.path!, withIntermediateDirectories: true, attributes: nil)
                print("Created directory at", destDir)
            } catch {
                // It must already exist
                print("Already exists!")
                updatingDeck = true
                //                return true
            }
        }
        
        // Get path of slides within that directory
        let pdfPath = destDir.URLByAppendingPathComponent("slides.pdf")
        
        if updatingDeck {
            do {
                try filemgr.removeItemAtURL(pdfPath)
            } catch {
                print("Couldn't remove item from", pdfPath)
            }
        }
        // Move slides from Inbox to new destination
        do {
            //
            if moving {
                try filemgr.moveItemAtURL(url, toURL:pdfPath)
            } else {
                try filemgr.copyItemAtURL(url, toURL:pdfPath)
            }
            
            if addingToList {
                let masterController = slideListController
                
                // Tell master controller about root directory for card deck
                if !updatingDeck {
                    masterController.insertNewSlides(destDir)
                } else {
                    masterController.reload()
                }
            }
        } catch {
            print("Failed")
            if self.window!.rootViewController?.presentedViewController == nil {
                let alertController = UIAlertController(title: "Problem", message: "Unable to copy PDF slides.", preferredStyle: .Alert)
                
                let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in print("ok") }
                alertController.addAction(OKAction)
                
                self.window!.rootViewController?.presentViewController(alertController, animated: true) {
                    print("what?")
                }
            }
        }
        
        // Do I need to release this document?
        let pdfDocument = CGPDFDocumentCreateWithURL(pdfPath)
        let numPages : Int = CGPDFDocumentGetNumberOfPages(pdfDocument)
        let numCards = numPages/2
        
        if updatingDeck {
            let destCards = destDir.URLByAppendingPathComponent("deck.dat")
            let deck = NSKeyedUnarchiver.unarchiveObjectWithFile(destCards.path!) as! Deck
            deck.resize(numCards)
            NSKeyedArchiver.archiveRootObject(deck, toFile: destCards.path!)
        } else {
            let deck : Deck = Deck(numCards: numCards, initCardLevel: 8)
            deck.start()
            let destCards = destDir.URLByAppendingPathComponent("deck.dat")
            NSKeyedArchiver.archiveRootObject(deck, toFile: destCards.path!)
        }
        
    }
    
    // This is what's done when "Open in..." dialogue is completed.
    func application(application: UIApplication, openURL url: NSURL,
                     sourceApplication: String?, annotation: AnyObject)-> Bool {
                        setUpSlideDeck(openURL: url, moving: true, addingToList:true)
                        
        return true
            
    }
    
}


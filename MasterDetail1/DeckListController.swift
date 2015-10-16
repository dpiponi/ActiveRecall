//
//  DeckListController.swift
//  MasterDetail1
//
//  Created by Dan Piponi on 10/1/15.
//  Copyright (c) 2015 Dan Piponi. All rights reserved.
//

import UIKit

// Will need...
// http://stackoverflow.com/questions/9509993/make-only-certain-sections-of-uitableview-editable

class DeckListController: UITableViewController {

    var detailViewController: SlideDeckController? = nil
    var slideRootDirs = [NSURL]()


    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? SlideDeckController
        }

        // Set up list of slide decks by enumerating contents
        // of Decks directory
        let filemgr = NSFileManager.defaultManager()
        do {
            let decksRoot : NSURL = documentsDirectory.URLByAppendingPathComponent("Decks")
            let directoryContents = try filemgr.contentsOfDirectoryAtPath(decksRoot.path!)
            for deckName in directoryContents {
                if deckName[deckName.startIndex] != "." { // XXX Insert new slides !!!
                    slideRootDirs.insert(decksRoot.URLByAppendingPathComponent(deckName), atIndex: 0)
                    let indexPath = NSIndexPath(forRow: 0, inSection: 0)
                    self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            }
        } catch {
        }
 
        
        setUpExamples()
        setUpDocumentation()
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didEnterBackground",
            name: UIApplicationDidEnterBackgroundNotification,
            object: nil)

    }

    func didEnterBackground() {
        self.presentedViewController?.dismissViewControllerAnimated(false, completion: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // This is where "Open in..." dialogue is completed by adding a new menu
    // entry.
    // The path is the root of the slide deck directory
    func insertNewSlides(rootSlidePath: NSURL) {
        slideRootDirs.insert(rootSlidePath, atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    func reload() {
        self.tableView.reloadData()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let slideRootDir = slideRootDirs[indexPath.row]
                let detailController = (segue.destinationViewController as! UINavigationController).topViewController as! SlideDeckController
                detailController.slideRootDir = slideRootDir
                detailController.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()

                // http://stackoverflow.com/questions/9273204/can-you-add-buttons-to-navigation-bars-through-storyboard
                
                detailController.navigationItem.leftItemsSupplementBackButton = true
                detailController.navigationItem.title = slideRootDir.lastPathComponent
            }
        }
    }
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return slideRootDirs.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) 

        let slideRootDir = slideRootDirs[indexPath.row]
        print(slideRootDir)
        let doc : CGPDFDocument = CGPDFDocumentCreateWithURL(slideRootDir.URLByAppendingPathComponent("slides.pdf"))!
        let numPages : Int = CGPDFDocumentGetNumberOfPages(doc)
        
        cell.textLabel!.text = slideRootDir.lastPathComponent!+" ("+String(numPages/2)+")" //description)
        
        // http://stackoverflow.com/questions/4107850/how-can-i-programatically-generate-a-thumbnail-of-a-pdf-with-the-iphone-sdk
        cell.imageView?.image = makeOrGetThumbnail(slideRootDir)
                
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let slideRootDir = slideRootDirs[indexPath.row]
            do {
                try NSFileManager.defaultManager().removeItemAtURL(slideRootDir)
            } catch {
                let window = UIApplication.sharedApplication().keyWindow
                if window?.rootViewController?.presentedViewController == nil {
                    let alertController = UIAlertController(title: "Problem", message: "Unable to delete slide deck.", preferredStyle: .Alert)
                    
                    let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                    alertController.addAction(OKAction)
                    
                    window?.rootViewController?.presentViewController(alertController, animated: true) {
                    }
                }
            }
            slideRootDirs.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    func setUpSlideDeck(openURL url: NSURL, moving: Bool, addingToList: Bool) {
        let filemgr = NSFileManager.defaultManager()
        
        let numPages : Int = numPDFPages(url)
        if numPages <= 1 {
            let window = UIApplication.sharedApplication().keyWindow
            if window!.rootViewController?.presentedViewController == nil {
                let alertController = UIAlertController(title: "Too few pages",
                    message: "Need 2 or more pages to make flash cards.",
                    preferredStyle: .Alert)
                
                let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                alertController.addAction(OKAction)
                
                window!.rootViewController?.presentViewController(alertController, animated: true) {
                }
            }
            
            do {
                try filemgr.removeItemAtURL(url)
            } catch {
            }
            
            return
        }
        
        let destDir : NSURL = documentsDirectory.URLByAppendingPathComponent("Decks")
            .URLByAppendingPathComponent(url.lastPathComponent!)
            .URLByDeletingPathExtension!
        
        
        var updatingDeck : Bool = false
        // Create that directory
        if (filemgr.fileExistsAtPath(destDir.path!)) {
            updatingDeck = true
        } else {
            do {
                try filemgr.createDirectoryAtPath(destDir.path!, withIntermediateDirectories: true, attributes: nil)
            } catch {
                // It must already exist
                // Though we already tested this and it shouldn't happen.
                updatingDeck = true
            }
        }
        
        // Get path of slides within that directory
        let pdfPath = destDir.URLByAppendingPathComponent("slides.pdf")
        
        if updatingDeck {
            do {
                try filemgr.removeItemAtURL(pdfPath)
            } catch {
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
                let masterController = self // XXX
                
                // Tell master controller about root directory for card deck
                if !updatingDeck {
                    masterController.insertNewSlides(destDir)
                } else {
                    masterController.reload()
                }
            }
        } catch {
            let window = UIApplication.sharedApplication().keyWindow
            if window!.rootViewController?.presentedViewController == nil {
                let alertController = UIAlertController(title: "Problem",
                    message: "Unable to copy PDF slides.",
                    preferredStyle: .Alert)
                
                let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                alertController.addAction(OKAction)
                
                window!.rootViewController?.presentViewController(alertController, animated: true) {
                }
            }
        }
        
        let numCards = numPages/2
        let destCards = destDir.URLByAppendingPathComponent("deck.dat")
        
        var deck : Deck!
        if updatingDeck {
            deck = NSKeyedUnarchiver.unarchiveObjectWithFile(destCards.path!) as! Deck
            deck.resize(numCards)
        } else {
            deck = Deck(numCards: numCards, initCardLevel: 8)
            deck.start()
        }
        NSKeyedArchiver.archiveRootObject(deck, toFile: destCards.path!)
    }

    @IBAction func doMenu(sender: UIBarButtonItem) {
        let window = UIApplication.sharedApplication().keyWindow
        if window?.rootViewController?.presentedViewController == nil {
            let alertController = UIAlertController(title: "Menu",
                message: "What do you want to do?",
                preferredStyle: .ActionSheet)
            
            for (title, action, style) in [
                ("Reinstall documentation", self.reinstallDocs, UIAlertActionStyle.Default),
                ("Reinstall example", self.reinstallExamples, UIAlertActionStyle.Default),
                ("Cancel", {() -> Void in  }, .Cancel)] {
                    let item = UIAlertAction(title: title, style: style) {
                        (_) in
                        action()
                    }
                    alertController.addAction(item)
                    
            }
            
            // Slight behaviour difference on iPad
            if let controller = alertController.popoverPresentationController {
                controller.barButtonItem = sender
            }
            
            window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
        }

    }
    
    func reinstallDocs() -> Void {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setBool(false, forKey: "docsInstalled")
        setUpDocumentation()
    }
    
    func reinstallExamples() -> Void {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setBool(false, forKey: "examplesInstalled")
        setUpExamples()
    }
    
    func setUpDocumentation() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if !defaults.boolForKey("docsInstalled") {
            let path = NSBundle.mainBundle().pathForResource("ActiveRecall", ofType:"pdf")
            let url = NSURL.fileURLWithPath(path!)
            setUpSlideDeck(openURL: url, moving:false, addingToList:true)
            defaults.setBool(true, forKey: "docsInstalled")
        }
    }
    
    func setUpExamples() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if !defaults.boolForKey("examplesInstalled") {
            let path = NSBundle.mainBundle().pathForResource("Flags", ofType:"pdf")
            let url = NSURL.fileURLWithPath(path!)
            setUpSlideDeck(openURL: url, moving:false, addingToList:true)
            defaults.setBool(true, forKey: "examplesInstalled")
        }
    }

}

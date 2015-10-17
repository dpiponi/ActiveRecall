//
//  DetailViewController.swift
//  MasterDetail1
//
//  Created by Dan Piponi on 10/1/15.
//  Copyright (c) 2015 Dan Piponi. All rights reserved.
//

import UIKit

class DeckController : UIViewController {

    @IBOutlet weak var pdfView: PDFView!
    var displayingFront : Bool = true
    var shouldDisplayFront : Bool = true
    
    func pageNumberFromDeck(deck : Deck)  -> Int {
        let n = 1+2*deck.cardIndices[0]+(self.displayingFront == self.shouldDisplayFront ? 0 : 1)
        return n
    }
    
    func setPage(deck: Deck) {
        pdfView.pageNumber = pageNumberFromDeck(deck)
    }

    func setPdf(url: NSURL) {
        pdfView.setPDF(url)
    }
    
    var slideRootDir: NSURL? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureView()
        
        if let slideRootDir: NSURL = self.slideRootDir {
            let slidesPath = slideRootDir.URLByAppendingPathComponent("slides.pdf")
            pdfView.setPDF(slidesPath)
            let deckURL : NSURL = slideRootDir.URLByAppendingPathComponent("deck.dat")
            let deck = NSKeyedUnarchiver.unarchiveObjectWithFile(deckURL.path!) as! Deck
            setPage(deck)
        }
        
        //
        // http://stackoverflow.com/questions/24049020/nsnotificationcenter-addobserver-in-swift
        // http://useyourloaf.com/blog/uialertcontroller-changes-in-ios-8.html
        //
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
    
    func withDeck(f : (Deck -> Void)) {
        if slideRootDir != nil {
            let deckURL : NSURL = slideRootDir!.URLByAppendingPathComponent("deck.dat")
            if NSFileManager.defaultManager().fileExistsAtPath(deckURL.path!) {
                let deck = NSKeyedUnarchiver.unarchiveObjectWithFile(deckURL.path!) as! Deck
                f(deck)
                NSKeyedArchiver.archiveRootObject(deck, toFile: deckURL.path!)
                self.setPage(deck)
            }
        }
    }
    
    @IBAction func doOptions(sender: UIBarButtonItem) {
        let window = UIApplication.sharedApplication().keyWindow
        if window?.rootViewController?.presentedViewController == nil {
            let alertController = UIAlertController(title: "Deck Options",
                                                    message: "What do you want to do?",
                                                    preferredStyle: .ActionSheet)
            
            for (title, action, style) in [("Reset", self.doReset, UIAlertActionStyle.Default),
                                           ("Shuffle", self.doShuffle, .Default),
                                           ("Flip", self.doReverse, .Default),
                                           ("Cancel", {() -> Void in  }, .Cancel)] {
                let resetAction = UIAlertAction(title: title, style: style) {
                    (_) in
                    action()
                }
                alertController.addAction(resetAction)
                
            }
            
            // Slight behaviour difference on iPad
            if let controller = alertController.popoverPresentationController {
                controller.barButtonItem = sender
            }
            
            window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
        }
    }

    // Handle user tap
    @IBAction func tapHandler(recognizer:UITapGestureRecognizer) {
        guard slideRootDir != nil else { return }
  
        withDeck {
            (deck) -> Void in
            let loc = recognizer.locationInView(self.pdfView)
            let slideWidth : CGFloat = self.pdfView.frame.size.width
            if loc.x > 2*slideWidth/3 {
                deck.correct()
                self.displayingFront = true
            } else if loc.x < slideWidth/3 {
                deck.incorrect()
                self.displayingFront = true
            } else {
                self.displayingFront = !self.displayingFront
            }
        }
    }
    
    @IBAction func pinchHandler(sender: UIPinchGestureRecognizer) {
        if sender.scale > 1 {
            pdfView.zoomed = true
        } else if sender.scale < 1 {
            pdfView.zoomed = false
        }
    }

    func doUndo() -> Void {
        withDeck {
            (deck) -> Void in
            deck.undo()
            self.displayingFront = true
        }
    }
    
    func doReset() -> Void {
        withDeck {
            (deck) -> Void in
            deck.reset()
            self.displayingFront = true
        }
    }
    
    func doReverse() -> Void {
        withDeck {
            (deck) -> Void in
            self.shouldDisplayFront = !self.shouldDisplayFront
        }
    }
    
    @IBAction func swipeLeftHandler(sender: AnyObject) {
        withDeck {
            (deck) -> Void in
            deck.undo()
            self.displayingFront = true
        }
    }
    @IBAction func swipeRightHandler(sender: AnyObject) {
        withDeck {
            (deck) -> Void in
            deck.moveFrontToBack()
            self.displayingFront = true
        }
    }
    
    func doShuffle() -> Void {
        self.withDeck {
            (deck) -> Void in
            deck.shuffle()
            self.displayingFront = true
        }
    }
}


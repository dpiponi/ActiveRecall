//
//  DetailViewController.swift
//  MasterDetail1
//
//  Created by Dan Piponi on 10/1/15.
//  Copyright (c) 2015 Dan Piponi. All rights reserved.
//

import UIKit


class DetailViewController: UIViewController {

    @IBOutlet weak var pdfView: PDFView!
    var displayingFront : Bool = true
    var shouldDisplayFront : Bool = true
    
    func pageNumberFromDeck(deck : Deck)  -> Int {
        let n = 1+2*deck.cardIndices[0]+(self.displayingFront == self.shouldDisplayFront ? 0 : 1)
        return n
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
            pdfView.pageNumber = pageNumberFromDeck(deck)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func withDeck(f : (Deck -> Void)) {
        let deckURL : NSURL = slideRootDir!.URLByAppendingPathComponent("deck.dat")
        if NSFileManager.defaultManager().fileExistsAtPath(deckURL.path!) {
            // Read in Deck
            let deck = NSKeyedUnarchiver.unarchiveObjectWithFile(deckURL.path!) as! Deck
            f(deck)
            // Write deck back out again
            NSKeyedArchiver.archiveRootObject(deck, toFile: deckURL.path!)
        }
    }

    
    @IBAction func doOptions(sender: UIBarButtonItem) {
        let window = UIApplication.sharedApplication().keyWindow
        if window?.rootViewController?.presentedViewController == nil {
            let alertController = UIAlertController(title: "Deck Options", message: "What do you want to do?", preferredStyle: .ActionSheet)
            
            
            let OKAction2 = UIAlertAction(title: "Reset", style: .Default) { (_) in
                self.doReset()
            }
            alertController.addAction(OKAction2)
            
            let OKAction = UIAlertAction(title: "Shuffle", style: .Default) { (_) in
                self.doShuffle() // YYY
            }
            alertController.addAction(OKAction)
                        
            let OKAction4 = UIAlertAction(title: "Reverse", style: .Default) { (_) in
                self.doReverse()
            }
            alertController.addAction(OKAction4)
            
            if let controller = alertController.popoverPresentationController {
                controller.barButtonItem = sender
            }
            
            window?.rootViewController?.presentViewController(alertController, animated: false) {
                print("what?")
            }
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
            self.pdfView.pageNumber = self.pageNumberFromDeck(deck)
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
            self.pdfView.pageNumber = self.pageNumberFromDeck(deck)
        }
    }
    
    func doReset() -> Void {
        withDeck {
            (deck) -> Void in
            deck.reset()
            self.pdfView.pageNumber = self.pageNumberFromDeck(deck)
        }
    }
    
    func doReverse() -> Void {
        withDeck {
            (deck) -> Void in
            self.shouldDisplayFront = !self.shouldDisplayFront
            self.pdfView.pageNumber = self.pageNumberFromDeck(deck)
        }
    }
    
    @IBAction func swipeLeftHandler(sender: AnyObject) {
        withDeck {
            (deck) -> Void in
            deck.undo()
            self.pdfView.pageNumber = self.pageNumberFromDeck(deck)
        }
    }
    @IBAction func swipeRightHandler(sender: AnyObject) {
        withDeck {
            (deck) -> Void in
            deck.moveFrontToBack()
            self.pdfView.pageNumber = self.pageNumberFromDeck(deck)
        }
    }
    
    func doShuffle() -> Void {
        self.withDeck {
            (deck) -> Void in
            deck.shuffle()
            self.displayingFront = true
            self.pdfView.pageNumber = self.pageNumberFromDeck(deck)
        }
    }
    
//    override func canBecomeFirstResponder() -> Bool {
//        return true
//    }


//    // http://stackoverflow.com/questions/27681887/how-to-fix-run-time-error-using-uialertcontroller
//    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
//        if motion == .MotionShake {
//            
//            
//            let window = UIApplication.sharedApplication().keyWindow
//            if window?.rootViewController?.presentedViewController == nil {
//                let alertController = UIAlertController(title: "Shake", message: "Do you wish to shuffle deck?", preferredStyle: .ActionSheet)
//                
//                let OKAction = UIAlertAction(title: "Yes", style: .Default) { (_) in
//                        self.withDeck({(deck) -> Void in
//                                deck.shuffle()
//                                self.displayingFront = true
//                                self.pdfView.pageNumber = self.pageNumberFromDeck(deck)
//                        })}
//                alertController.addAction(OKAction)
//                let OKAction2 = UIAlertAction(title: "No", style: .Default) { (action) in print("ok") }
//                alertController.addAction(OKAction2)
//
//                if let controller = alertController.popoverPresentationController {
//                    controller.sourceView = self.view;
//                    controller.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
//                }
//                
//                window?.rootViewController?.presentViewController(alertController, animated: true) {
//                    print("what?")
//                }
//            }
//
//            
//        }
//    }

}


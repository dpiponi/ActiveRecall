//
//  Utils.swift
//  MasterDetail1
//
//  Created by Dan Piponi on 10/14/15.
//  Copyright © 2015 Dan Piponi. All rights reserved.
//

import Foundation

let documentsDirectory : NSURL = NSFileManager.defaultManager().URLsForDirectory(
    NSSearchPathDirectory.DocumentDirectory,
    inDomains: NSSearchPathDomainMask.UserDomainMask)[0]

func deckPDFURL(deckRootDir : NSURL) -> NSURL {
    return deckRootDir.URLByAppendingPathComponent("slides.pdf")
}

func deckDatURL(deckRootDir : NSURL) -> NSURL {
    return deckRootDir.URLByAppendingPathComponent("deck.dat")
}

//
//  PDFBorder.swift
//  MasterDetail1
//
//  Created by Dan Piponi on 10/8/15.
//  Copyright © 2015 Dan Piponi. All rights reserved.
//

import Foundation
import UIKit

func numPDFPages(pdfFile : NSURL) -> Int {
    let pdf : CGPDFDocument = CGPDFDocumentCreateWithURL(pdfFile)!
    let numPages : Int = CGPDFDocumentGetNumberOfPages(pdf)

    return numPages
}

//
// http://stackoverflow.com/questions/11592313/how-do-i-save-a-uiimage-to-a-file
//
func makeOrGetThumbnail(deckPath: NSURL) -> UIImage {
    let thumbnailPath = deckPath.URLByAppendingPathComponent("thumbnail.jpg")
    if NSFileManager.defaultManager().fileExistsAtPath(thumbnailPath.path!) {
        print("Restoring thumbnail", thumbnailPath)
        let thumbnailImage = UIImage(contentsOfFile: thumbnailPath.path!)
        print("image=", thumbnailImage)
        return thumbnailImage!
    } else {
        let deckPath = deckPDFURL(deckPath)
        let thumbnailImage : UIImage = makeThumbnail(deckPath)
        let pngImage : NSData = UIImageJPEGRepresentation(thumbnailImage, 0.8)!
        pngImage.writeToFile(thumbnailPath.path!, atomically: true)
        print("Creating thumbnail, storing at", thumbnailPath)
        return thumbnailImage
    }
}

func computeMean(bdat: UnsafeMutablePointer<UInt8>, iwidth: Int, iheight: Int, bytesPerPixel: Int, bytesPerRow: Int) -> (CGFloat, CGFloat, CGFloat) {
    let borderMean = foldBorder(bdat,
        iwidth: iwidth, iheight: iheight,
        bytesPerPixel: bytesPerPixel, bytesPerRow: bytesPerRow,
        x0: (tr:CGFloat(0.0), tg:CGFloat(0.0), tb:CGFloat(0.0), count:0)) {
            (bdat, x0) in
            
            var x : (tr: CGFloat, tg: CGFloat, tb: CGFloat, count: Int)
            
            let alpha : CGFloat = CGFloat(bdat[3])/255.0
            x.tr = x0.tr+linstep(alpha, a: CGFloat(1.0), b: CGFloat(bdat[0])/CGFloat(255))
            x.tg = x0.tg+linstep(alpha, a: CGFloat(1.0), b: CGFloat(bdat[1])/CGFloat(255))
            x.tb = x0.tb+linstep(alpha, a: CGFloat(1.0), b: CGFloat(bdat[2])/CGFloat(255))
            x.count = x0.count+1
            
            return x
    }
    let medianR = borderMean.tr/CGFloat(borderMean.count)
    let medianG = borderMean.tg/CGFloat(borderMean.count)
    let medianB = borderMean.tb/CGFloat(borderMean.count)
    
    return (medianR, medianG, medianB)
}

func iterateMedian(median: (CGFloat, CGFloat, CGFloat), bdat: UnsafeMutablePointer<UInt8>, iwidth: Int, iheight: Int, bytesPerPixel: Int, bytesPerRow: Int) -> (CGFloat, CGFloat, CGFloat) {
    let borderMedianStep = foldBorder(bdat,
        iwidth: iwidth, iheight: iheight,
        bytesPerPixel: bytesPerPixel, bytesPerRow: bytesPerRow,
        x0: (tr:CGFloat(0.0), tg:CGFloat(0.0), tb:CGFloat(0.0), wsum:CGFloat(0.0))) {
            (bdat, x0) in

            var x : (tr: CGFloat, tg: CGFloat, tb: CGFloat, wsum: CGFloat)

            let alpha : CGFloat = CGFloat(bdat[3])/255.0
            let r = linstep(alpha, a: CGFloat(1.0), b: CGFloat(bdat[0])/CGFloat(255))
            let g = linstep(alpha, a: CGFloat(1.0), b: CGFloat(bdat[1])/CGFloat(255))
            let b = linstep(alpha, a: CGFloat(1.0), b: CGFloat(bdat[2])/CGFloat(255))

            let w = CGFloat(1.0)/CGFloat(sqrt(Float((r-median.0)*(r-median.0)+(g-median.1)*(g-median.1)+(b-median.2)*(b-median.2)))+1e-10)

            x.tr = x0.tr+w*r
            x.tg = x0.tg+w*g
            x.tb = x0.tb+w*b
            x.wsum = x0.wsum+w

            return x
    }

    let medianR = borderMedianStep.tr/borderMedianStep.wsum
    let medianG = borderMedianStep.tg/borderMedianStep.wsum
    let medianB = borderMedianStep.tb/borderMedianStep.wsum
    
    return (medianR, medianG, medianB)
}

//
// http://stackoverflow.com/questions/4107850/how-can-i-programatically-generate-a-thumbnail-of-a-pdf-with-the-iphone-sdk
//
func makeThumbnail(pdfFile: NSURL) -> UIImage {
    let pdf : CGPDFDocument = CGPDFDocumentCreateWithURL(pdfFile)!
    let border : UIColor = PDFBorder(pdf, pageNumber: 1)
    
    let aRect : CGRect = CGRectMake(0, 0, 100, 70); // thumbnail size
    UIGraphicsBeginImageContext(aRect.size);    let context : CGContextRef = UIGraphicsGetCurrentContext()!
    var thumbnailImage : UIImage
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0.0, aRect.size.height)
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextSetGrayFillColor(context, 1.0, 1.0)
    CGContextSetFillColorWithColor(context, border.CGColor)
    CGContextFillRect(context, aRect);
    
    
    // Grab the first PDF page
    let page : CGPDFPage = CGPDFDocumentGetPage(pdf, 1)!
    let pdfTransform : CGAffineTransform = CGPDFPageGetDrawingTransform(page, .MediaBox, aRect, 0, true)
    // And apply the transform.
    CGContextConcatCTM(context, pdfTransform);
    
    CGContextDrawPDFPage(context, page);
    
    // Create the new UIImage from the context
    thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
    
    //Use thumbnailImage (e.g. drawing, saving it to a file, etc)
    
    CGContextRestoreGState(context);
    
    UIGraphicsEndImageContext();
    
    return thumbnailImage
}

func foldBorder<X>(bdat: UnsafeMutablePointer<UInt8>,
    iwidth: Int, iheight: Int,
    bytesPerPixel: Int,
    bytesPerRow: Int,
    x0: X,
    f : (UnsafeMutablePointer<UInt8>, X) -> X) -> X {
        var x : X = x0
        for i in 0..<iwidth {
            x = f(bdat+4*i, x)
            x = f(bdat+(iheight-1)*bytesPerRow+4*i, x)
        }
        for i in 0..<iheight {
            x = f(bdat+i*bytesPerRow, x)
            x = f(bdat+(iwidth-1)*bytesPerPixel+i*bytesPerRow, x)
        }
        return x
}

//
// http://stackoverflow.com/questions/24073135/generic-type-constraint-for-numerical-type-only
//
protocol Num {
    init(_ v: Int)
    func +(lhs: Self, rhs: Self) -> Self
    func -(lhs: Self, rhs: Self) -> Self
    func *(lhs: Self, rhs: Self) -> Self
}

extension CGFloat : Num { }

func linstep<X:Num>(lambda: X, a: X, b: X) -> X {
    return (X(1)-lambda)*a+lambda*b
}

// Pick colour for border around deck.
func PDFBorder(document: CGPDFDocument, pageNumber: Int) -> UIColor {
    let page = CGPDFDocumentGetPage(document, pageNumber)
    let pageRect = CGPDFPageGetBoxRect(page, .MediaBox)
    let width = pageRect.size.width;
    let height = pageRect.size.height;
    
    let downScale : CGFloat = max(width, height)/128.0
    let iwidth = Int(width/downScale)
    let iheight = Int(height/downScale)
    
    let colorSpace : CGColorSpace = CGColorSpaceCreateDeviceRGB()!
    let bytesPerPixel : Int = 4
    let bytesPerRow : Int = bytesPerPixel*iwidth
    let bitsPerComponent : Int = 8
    
    //
    // Use http://swiftdoc.org/v2.0/type/UnsafeMutablePointer/
    //
    let bitmapData = malloc(Int(bytesPerPixel*iwidth*iheight))
    let bdat = UnsafeMutablePointer<UInt8>(bitmapData)
    
    //
    // https://developer.apple.com/library/ios/documentation/GraphicsImaging/Reference/CGBitmapContext/#//apple_ref/swift/tdef/c:@T@CGBitmapContextReleaseDataCallback
    //
    let maybeContext2 : CGContextRef? = CGBitmapContextCreateWithData(bitmapData,
        iwidth, iheight,
        bitsPerComponent, bytesPerRow,
        colorSpace,
        CGImageAlphaInfo.PremultipliedLast.rawValue | CGBitmapInfo.ByteOrder32Big.rawValue,
        {(releaseInfo, data) -> Void in free(data)},
        nil)
    let context2 = maybeContext2!
    CGContextSaveGState(context2);
    CGContextSetBlendMode(context2, .Copy);
    
    let xoffset : CGFloat = 0.0
    let yoffset : CGFloat = 0.0
    
    CGContextSetFillColorWithColor(context2, UIColor.whiteColor().CGColor)
    CGContextTranslateCTM(context2, 0.5*CGFloat(iwidth), 0.5*CGFloat(iheight))
    CGContextScaleCTM(context2, 1.0/CGFloat(downScale), -1.0/CGFloat(downScale))
    CGContextTranslateCTM(context2, -0.5*width-xoffset, -0.5*height+yoffset)
    
    for i in 0..<4 {
        bdat[i] = 255
    }
    
    CGContextDrawPDFPage(context2, page)
    
    var (medianR, medianG, medianB) = computeMean(bdat, iwidth: iwidth, iheight: iheight, bytesPerPixel: bytesPerPixel, bytesPerRow: bytesPerRow)
    for _ in 0..<40 {
        (medianR, medianG, medianB) = iterateMedian((medianR, medianG, medianB), bdat: bdat, iwidth: iwidth, iheight: iheight, bytesPerPixel: bytesPerPixel, bytesPerRow: bytesPerRow)
//        print(medianR, medianG, medianB)
    }
    
    CGContextRestoreGState(context2);
    
    // http://stackoverflow.com/questions/9444295/ios-does-cgbitmapcontextcreate-copy-data
    //    free(bitmapData)
    
    //    self.backgroundColor = UIColor(red: CGFloat(bdat[0])/255.0, green: CGFloat(bdat[1])/255.0, blue: CGFloat(bdat[2])/255.0, alpha: CGFloat(1.0))
    return UIColor(red: medianR, green: medianG, blue: medianB, alpha: CGFloat(1.0))
}

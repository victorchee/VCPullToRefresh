//
//  ViewController.swift
//  VCPullToRefresh
//
//  Created by qihaijun on 4/7/15.
//  Copyright (c) 2015 VictorChee. All rights reserved.
//

import UIKit
import QuartzCore
import CoreText

class StrokeTextLoadingViewController: UICollectionViewController {

    //! The layer that is animated as the user pulls down
    var pullToRefreshShape: CAShapeLayer!
    //! A view that contain both the pull to refresh and loading layers
    var loadingIndicator: UIView!
    //! If new data is currently being loaded
    var isLoading: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupLoadingIndicator()
        
        self.pullToRefreshShape.addAnimation(pullDownAnimation(), forKey: "Write 'Load' as you drag down")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //! Two stroked shape layers that form the text 'Load' and 'ing'
    func setupLoadingIndicator() {
        self.loadingIndicator = UIView(frame: CGRect(x: 0, y: -150, width: CGRectGetWidth(self.view.frame), height: 150))
        self.collectionView?.addSubview(self.loadingIndicator)
        
        self.pullToRefreshShape = CAShapeLayer()
        var suggestSize: CGSize;
        (self.pullToRefreshShape.path, suggestSize) = loadPathWithText(text: "Loading")
        
        self.pullToRefreshShape.strokeColor = UIColor.blackColor().CGColor
        self.pullToRefreshShape.fillColor = UIColor.clearColor().CGColor
        self.pullToRefreshShape.lineCap = kCALineCapRound
        self.pullToRefreshShape.lineJoin = kCALineJoinRound
        self.pullToRefreshShape.lineWidth = 5
        self.pullToRefreshShape.position = CGPointMake((CGRectGetWidth(self.loadingIndicator.frame) - suggestSize.width)/2, (CGRectGetHeight(self.loadingIndicator.frame) - suggestSize.height)/2)
        self.pullToRefreshShape.strokeEnd = 0
        self.loadingIndicator.layer.addSublayer(self.pullToRefreshShape)
        
        self.pullToRefreshShape.speed = 0 // pull to refresh layer is paused here
    }
    
    func loadPathWithText(#text: String)->(path: CGPath!, suggestSize: CGSize) {
        let letters: CGMutablePathRef = CGPathCreateMutable()
        let font: CTFontRef = CTFontCreateWithName("Helvetica-Bold", 72, nil)
        let attributedString = NSAttributedString(string: "Loading", attributes: [kCTFontAttributeName: font])
        
        // 字体的Size
        let framesetter: CTFramesetterRef = CTFramesetterCreateWithAttributedString(attributedString)
        let suggestSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), nil, CGSizeMake(CGFloat.max, CGFloat.max), nil)
        
        let line: CTLineRef = CTLineCreateWithAttributedString(attributedString)
        let runArray: CFArrayRef = CTLineGetGlyphRuns(line)
        // For each RUN
        for runIndex in 0 ..< CFArrayGetCount(runArray) {
            // Get FONT for this run
            let run: CTRunRef = unsafeBitCast(CFArrayGetValueAtIndex(runArray, runIndex), CTRunRef.self)
            let runFont: CTFontRef = unsafeBitCast(CFDictionaryGetValue(CTRunGetAttributes(run), unsafeBitCast(kCTFontAttributeName, UnsafePointer.self)), CTFontRef.self)
            // For each GLYPH in run
            for runGlyphIndex in 0 ..< CTRunGetGlyphCount(run) {
                // Get Glyph & Glyph-data
                let thisGlyphRange: CFRange = CFRangeMake(runGlyphIndex, 1)
                var glyph: CGGlyph = 0
                var position: CGPoint = CGPointZero
                CTRunGetGlyphs(run, thisGlyphRange, &glyph)
                CTRunGetPositions(run, thisGlyphRange, &position)
                
                // Get PATH of outline
                let letter: CGPathRef = CTFontCreatePathForGlyph(runFont, glyph, nil)
                // 坐标系转换
                var transform: CGAffineTransform = CGAffineTransformMake(1, 0, 0, -1, position.x, self.loadingIndicator.frame.size.height+position.y)
                CGPathAddPath(letters, &transform, letter)
            }
        }
        
        let bezierPath = UIBezierPath()
        bezierPath.moveToPoint(CGPointZero)
        bezierPath.appendPath(UIBezierPath(CGPath: letters))
        
        return (bezierPath.CGPath, suggestSize)
    }
    
    //! This is the animation that is controlled using timeOffset when the user pulls down
    func pullDownAnimation() -> CAAnimation {
        // Text is drawn by stroking the path from 0% to 100%
        let writeText: CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        writeText.fromValue = NSNumber(integer: 0)
        writeText.toValue = NSNumber(integer: 1)
        
        // The layer is moved up so that the larger loading layer can fit above the cells
        let move: CABasicAnimation = CABasicAnimation(keyPath: "position.y")
        move.byValue = NSNumber(integer: -22)
        move.toValue = NSNumber(integer: 0)
        
        let group: CAAnimationGroup = CAAnimationGroup()
        group.duration = 1.0 // For convenience when using timeOffset to control the animation
        group.animations = [writeText, move]
        
        return group
    }
    
    //! This is the magic of the entire
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset: CGFloat = scrollView.contentOffset.y + scrollView.contentInset.top
        
        if offset <= 0 && !self.isLoading && self.isViewLoaded() {
            let startLoadingThreshold: CGFloat = 60.0
            let fractionDragged: CGFloat = -offset / startLoadingThreshold
            
            self.pullToRefreshShape.timeOffset = min(1.0, Double(fractionDragged))
            
            if fractionDragged >= 1.0 {
                startLoading()
            }
        }
    }
    
    //! Start the loading animation and load more data
    func startLoading() {
        self.isLoading = true
        
        let contentTopInset: CGFloat = self.collectionView!.contentInset.top
        // insert the top to keep the loading indicator on screen
        self.collectionView?.contentInset = UIEdgeInsetsMake(contentTopInset + CGRectGetHeight(self.loadingIndicator.frame), 0, 0, 0)
        self.collectionView?.scrollEnabled = false // no further scrolling
        
        // Start loading
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
            // End loading
            UIView.animateWithDuration(1, animations: { () -> Void in
                self.collectionView?.contentInset = UIEdgeInsetsMake(contentTopInset, 0, 0, 0)
                // reset everything after completion
                self.loadingIndicator.alpha = 1.0
                self.collectionView?.scrollEnabled = true
                self.pullToRefreshShape.timeOffset = 0 // back to the start
                self.isLoading = false
            })
        }
    }
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! UICollectionViewCell
        
        return cell
    }
}


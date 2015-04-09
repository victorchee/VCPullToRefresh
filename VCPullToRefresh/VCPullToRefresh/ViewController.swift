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

class ViewController: UICollectionViewController {

    //! The layer that is animated as the user pulls down
    var pullToRefreshShape: CAShapeLayer!
    //! The layer that is animated as the app is loading more data
    var loadingShape: CAShapeLayer!
    //! A view that contain both the pull to refresh and loading layers
    var loadingIndicator:UIView!
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
        self.loadingShape = CAShapeLayer()
        self.loadingShape.path = ingPath()
        
        for shape in [self.pullToRefreshShape, self.loadingShape] {
            shape.strokeColor = UIColor.blackColor().CGColor
            shape.fillColor = UIColor.clearColor().CGColor
            shape.lineCap = kCALineCapRound
            shape.lineJoin = kCALineJoinRound
            shape.lineWidth = 5
            shape.position = CGPointMake((CGRectGetWidth(self.loadingIndicator.frame) - suggestSize.width)/2, (CGRectGetHeight(self.loadingIndicator.frame) - suggestSize.height)/2)
            shape.strokeEnd = 0
            self.loadingIndicator.layer.addSublayer(shape)
        }
        
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
    
    func loadPath()->CGPathRef {
        let letters: CGMutablePathRef = CGPathCreateMutable()
        let font: CTFontRef = CTFontCreateWithName("Helvetica-Bold", 72, nil)
        let attributedString = NSAttributedString(string: "Loading", attributes: [kCTFontAttributeName: font])
        
        let framesetter: CTFramesetterRef = CTFramesetterCreateWithAttributedString(attributedString)
        let suggestSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), nil, CGSizeMake(300, CGFloat(MAXFLOAT)), nil)
        
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
        
        return bezierPath.CGPath
    }
    
    func ingPath()->CGPathRef {
        let path = CGPathCreateMutable()
        // ing (minus dot)
        CGPathMoveToPoint(path,     nil, 139.569336, 42.9423837);
        CGPathAddCurveToPoint(path, nil, 139.569336, 42.9423837, 149.977539, 32.9609375, 151.100586, 27.9072266);
        CGPathAddCurveToPoint(path, nil, 152.223633, 22.8535156, 149.907226, 21.5703124, 148.701172, 26.5419921);
        CGPathAddCurveToPoint(path, nil, 147.495117, 31.5136718, 142.760742, 50.8046884, 149.701172, 48.2763681);
        CGPathAddCurveToPoint(path, nil, 156.641602, 45.7480478, 166.053711, 33.5791017, 167.838867, 29.5136719);
        CGPathAddCurveToPoint(path, nil, 169.624023, 25.4482421, 169.426758, 20.716797,  167.455078, 26.1152344);
        CGPathAddCurveToPoint(path, nil, 165.483398, 31.5136718, 165.618164, 42.9423835, 163.97168,  48.2763678);
        CGPathAddCurveToPoint(path, nil, 163.97168,  48.2763678, 163.897461, 41.4570313, 168.141602, 35.9375);
        CGPathAddCurveToPoint(path, nil, 172.385742, 30.4179687, 179.773438, 21.9091796, 183.285645, 26.6875);
        CGPathAddCurveToPoint(path, nil, 186.797851, 31.4658204, 177.178223, 48.2763684, 184.285645, 48.2763678);
        CGPathAddCurveToPoint(path, nil, 191.393066, 48.2763678, 196.006836, 38.8701172, 198.850586, 34.0449218);
        CGPathAddCurveToPoint(path, nil, 201.694336, 29.2197264, 207.908203, 19.020508,  216.71875,  28.4179687);
        CGPathAddCurveToPoint(path, nil, 216.71875,  28.4179687, 211.086914, 23.5478516, 206.945312, 24.6738281);
        CGPathAddCurveToPoint(path, nil, 202.803711, 25.7998046, 194.8125,   40.1455079, 201.611328, 47.2763672);
        CGPathAddCurveToPoint(path, nil, 208.410156, 54.4072265, 220.274414, 30.9111327, 221.274414, 26.6874999);
        CGPathAddCurveToPoint(path, nil, 222.274414, 22.4638672, 220.005859, 20.3759766, 218.523438, 28.5419922);
        CGPathAddCurveToPoint(path, nil, 217.041016, 36.7080077, 216.630859, 64.7705084, 209.121094, 71.012696);
        CGPathAddCurveToPoint(path, nil, 201.611328, 77.2548835, 197.109375, 65.0654303, 202.780273, 60.9287116);
        CGPathAddCurveToPoint(path, nil, 208.451172, 56.7919928, 224.84668,  51.0244147, 228.638672, 38.6855466);
        
        // dot
        CGPathMoveToPoint(path,     nil, 153.736328, 14.953125);
        CGPathAddCurveToPoint(path, nil, 153.736328, 14.953125,  157.674805, 12.8178626, 155.736328, 10.2929688);
        CGPathAddCurveToPoint(path, nil, 153.797852, 7.76807493, 151.408203, 12.2865614, 152.606445, 14.9531252);
        
        let transform = CGAffineTransformMakeScale(0.7, 0.7); // It was slighly to big and I didn't feel like redoing it :D
//        return CGPathCreateCopyByTransformingPath(path, &transform);
        return path
    }
    
    //! This is the animation that is controlled using timeOffset when the user pulls down
    func pullDownAnimation()->CAAnimation {
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
        
        // start the loading animation
        self.loadingShape.addAnimation(loadingAnimation(), forKey: "Write that word")
        
        let contentTopInset: CGFloat = self.collectionView!.contentInset.top
        // insert the top to keep the loading indicator on screen
        self.collectionView?.contentInset = UIEdgeInsetsMake(contentTopInset + CGRectGetHeight(self.loadingIndicator.frame), 0, 0, 0)
        self.collectionView?.scrollEnabled = false // no further scrolling
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.collectionView?.contentInset = UIEdgeInsetsMake(contentTopInset, 0, 0, 0)
            self.loadingIndicator.alpha = 0
        })
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.8 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
            // reset everything after completion
            self.loadingShape.removeAllAnimations()
            self.loadingIndicator.alpha = 1.0
            self.collectionView?.scrollEnabled = true
            self.pullToRefreshShape.timeOffset = 0 // back to the start
            self.isLoading = false
        }
    }
    
    //! The loading animation is quickly drawing the last the letters (ing)
    func loadingAnimation()->CAAnimation {
        let write2: CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        write2.fromValue = NSNumber(integer: 0)
        write2.toValue = NSNumber(integer: 1)
        write2.fillMode = kCAFillModeBoth
        write2.removedOnCompletion = false
        write2.duration = 0.4
        return write2
    }
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as UICollectionViewCell
        
        return cell
    }
}


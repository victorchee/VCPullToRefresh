//
//  UIScrollView+StrokeText.swift
//  VCPullToRefresh
//
//  Created by qihaijun on 9/8/15.
//  Copyright (c) 2015 VictorChee. All rights reserved.
//

import UIKit

class LoadingView: UIView {
    
    enum LoadingState {
        case Stopped
        case Triggered
        case Loading
    }
    
    var state: LoadingState = .Stopped {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
            
            switch self.state {
            case .Stopped:
                self.resetScrollViewContentInset()
            case .Loading:
                setScrollViewContentInsetForLoading()
                if oldValue == .Triggered {
                    self.action?()
                }
            default:
                break;
            }
        }
    }
    var shapeLayer: CAShapeLayer!
    var activityIndicatorView: UIActivityIndicatorView!
    var action: (() -> Void)?
    var scrollView: UIScrollView?
    var originalTopInset: CGFloat = 0.0
    var isObserving = false
    var wasTriggeredByUser = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor.orangeColor().CGColor
        shapeLayer.fillColor = UIColor.clearColor().CGColor
        shapeLayer.lineCap = kCALineCapRound
        shapeLayer.lineJoin = kCALineJoinRound
        var suggestSize: CGSize
        (shapeLayer.path, suggestSize) = loadPathWithText(text: "VC")
        shapeLayer.position = CGPoint(x: (frame.width - suggestSize.width)/2.0, y: (frame.height - suggestSize.height)/2.0)
        shapeLayer.strokeEnd = 0.0
        shapeLayer.speed = 0.0 // pause
        shapeLayer.addAnimation(pullDownAnimation(), forKey: "pull down animation")
        layer.addSublayer(shapeLayer)
        
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White);
        activityIndicatorView.center = CGPoint(x: frame.width/2.0, y: frame.height/2.0)
        activityIndicatorView.hidesWhenStopped = true
        self.addSubview(activityIndicatorView)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        if superview != nil && newSuperview == nil {
            let scrollView = self.superview as! UIScrollView
            if scrollView.enableLoading && isObserving {
                scrollView.removeObserver(self, forKeyPath: "contentOffset")
                scrollView.removeObserver(self, forKeyPath: "contentSize")
                scrollView.removeObserver(self, forKeyPath: "frame")
                isObserving = false
            }
        }
    }
    
    private func loadPathWithText(#text: String)->(path: CGPath!, suggestSize: CGSize) {
        let letters: CGMutablePathRef = CGPathCreateMutable()
        let font: CTFontRef = CTFontCreateWithName("Helvetica-Bold", 50, nil)
        let attributedString = NSAttributedString(string: text, attributes: [kCTFontAttributeName: font])
        
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
                var transform: CGAffineTransform = CGAffineTransformMake(1, 0, 0, -1, position.x, scrollView?.frame.height ?? 60.0 + position.y)
                CGPathAddPath(letters, &transform, letter)
            }
        }
        
        let bezierPath = UIBezierPath()
        bezierPath.moveToPoint(CGPointZero)
        bezierPath.appendPath(UIBezierPath(CGPath: letters))
        
        return (bezierPath.CGPath, suggestSize)
    }
    
    func startAnimating() {
        if scrollView!.contentOffset.y == -scrollView!.contentInset.top {
            scrollView?.setContentOffset(CGPoint(x: scrollView!.contentOffset.x, y: -originalTopInset - frame.height), animated: true)
            wasTriggeredByUser = false
//            pullingAnimation(scrollView!.contentOffset)
        } else {
            wasTriggeredByUser = true
        }
        state = .Loading
        activityIndicatorView.startAnimating()
    }
    
    func stopAnimating() {
        activityIndicatorView.stopAnimating()
        shapeLayer.timeOffset = 0.0
        state = .Stopped
        if !wasTriggeredByUser {
            scrollView?.setContentOffset(CGPoint(x: scrollView!.contentOffset.x, y: -originalTopInset), animated: true)
        }
    }
    
    private func resetScrollViewContentInset() {
        if var currentInsets = scrollView?.contentInset {
            currentInsets.top = originalTopInset
            setScrollViewContentInset(currentInsets)
        }
    }
    
    private func setScrollViewContentInsetForLoading() {
        if var currentInsets = scrollView?.contentInset {
            let offset = max(scrollView!.contentOffset.y * -1, 0.0)
            currentInsets.top = min(offset, originalTopInset + frame.height)
            setScrollViewContentInset(currentInsets)
        }
    }
    
    private func setScrollViewContentInset(insert: UIEdgeInsets) {
        UIView.animateWithDuration(0.75, delay: 0, options: UIViewAnimationOptions.AllowUserInteraction | .BeginFromCurrentState, animations: { () -> Void in
            self.scrollView?.contentInset = insert
            if self.state == .Stopped {
                // finish animation
            }
            }) { (finished) -> Void in
                
        }
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if keyPath == "contentOffset" {
            scrollViewDidScroll(change[NSKeyValueChangeNewKey]?.CGPointValue())
        } else if keyPath == "contentSize" {
            frame = CGRect(x: 0.0, y: -frame.height, width: scrollView?.frame.width ?? 0, height: frame.height)
            layoutSubviews()
        } else if keyPath == "frame" {
            layoutSubviews()
        }
    }
    
    private func scrollViewDidScroll(contentOffset: CGPoint?) {
        if let offset = contentOffset {
            if state != .Loading {
                let scrollOffsetThreshold = frame.origin.y - originalTopInset
                
                if !scrollView!.dragging && state == .Triggered {
                    state = .Loading
                    startAnimating()
                } else if offset.y < scrollOffsetThreshold && scrollView!.dragging && state == .Stopped {
                    state = .Triggered
//                    pullingAnimation(offset)
                } else if offset.y >= scrollOffsetThreshold && !scrollView!.dragging && state != .Stopped {
                    state = .Stopped
                } else if (scrollView!.dragging && state == .Stopped) {
                    // pulling down
                    let y = offset.y + originalTopInset
                    
                    if y <= 0  {
                        let startLoadingThreshold: CGFloat = 60.0
                        let fractionDragged: CGFloat = -y / startLoadingThreshold
                        
                        shapeLayer.timeOffset = min(1.0, Double(fractionDragged))
                    }
                }
            }
        }
    }
    
    //! This is the animation that is controlled using timeOffset when the user pulls down
    func pullDownAnimation() -> CAAnimation {
        // Text is drawn by stroking the path from 0% to 100%
        let writeText: CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        writeText.fromValue = NSNumber(integer: 0)
        writeText.toValue = NSNumber(integer: 1)
        
        // The layer is moved up so that the larger loading layer can fit above the cells
        let move: CABasicAnimation = CABasicAnimation(keyPath: "position.y")
        move.fromValue = NSNumber(integer: 15)
        move.byValue = NSNumber(integer: 0)
        move.toValue = NSNumber(integer: -15)
        
        let group: CAAnimationGroup = CAAnimationGroup()
        group.duration = 1.0 // For convenience when using timeOffset to control the animation
        group.animations = [writeText, move]
        
        return group
    }
}

extension UIScrollView {
    private struct Constant {
        static var AssociatedKey = "LoadingView"
        static let LoadingViewHeight: CGFloat = 60.0
    }
    
    dynamic var loadingView: LoadingView {
        get {
            return objc_getAssociatedObject(self, &Constant.AssociatedKey) as! LoadingView
        }
        
        set {
            willChangeValueForKey("loadingView")
            objc_setAssociatedObject(self, &Constant.AssociatedKey, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_ASSIGN));
            didChangeValueForKey("loadingView")
        }
    }
    
    dynamic var enableLoading: Bool {
        get {
            return !loadingView.hidden
        }
        
        set {
            loadingView.hidden = !newValue
            
            if newValue {
                if !loadingView.isObserving {
                    addObserver(loadingView, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.New, context: nil)
                    addObserver(loadingView, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.New, context: nil)
                    addObserver(loadingView, forKeyPath: "frame", options: NSKeyValueObservingOptions.New, context: nil)
                    loadingView.isObserving = true
                    loadingView.frame = CGRect(x: 0.0, y: -Constant.LoadingViewHeight, width: frame.width, height: Constant.LoadingViewHeight)
                }
            } else {
                if loadingView.isObserving {
                    removeObserver(loadingView, forKeyPath: "contentOffset")
                    removeObserver(loadingView, forKeyPath: "contentSize")
                    removeObserver(loadingView, forKeyPath: "frame")
                    loadingView.resetScrollViewContentInset()
                    loadingView.isObserving = false
                }
            }
        }
    }
    
    func addLoadingWithActionHandler(actionHandler: () -> Void) {
        let view = LoadingView(frame: CGRect(x: 0.0, y: -Constant.LoadingViewHeight, width: frame.width, height: Constant.LoadingViewHeight))
        view.clipsToBounds = true
        view.action = actionHandler
        view.scrollView = self
        view.originalTopInset = contentInset.top
        addSubview(view)
        loadingView = view
        enableLoading = true
    }
    
    func triggerLoading() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.loadingView.state = .Triggered
            self.loadingView.startAnimating()
        })
    }
    
    func stopLoading() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.loadingView.state = .Stopped
            self.loadingView.stopAnimating()
        })
    }
    
}

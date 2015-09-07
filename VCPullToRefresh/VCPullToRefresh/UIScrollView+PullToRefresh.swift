//
//  UIScrollView+VCPullToRefresh.swift
//  VCPullToRefresh
//
//  Created by qihaijun on 9/1/15.
//  Copyright (c) 2015 VictorChee. All rights reserved.
//
//  Pull to refresh

import UIKit

let PullToRefreshViewHeight: CGFloat = 60.0

class PullToRefreshView: UIView {
    
    enum PullToRefreshState {
        case Stopped
        case Triggered
        case Loading
    }
    
    var state: PullToRefreshState = .Stopped {
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
    var waterDropLayer: CAShapeLayer!
    var indicator: UIActivityIndicatorView!
    var action: (() -> Void)?
    var scrollView: UIScrollView?
    var originalTopInset: CGFloat = 0.0
    var isObserving = false
    var wasTriggeredByUser = true
    
    let waterDropTopRadius: CGFloat = 15.0
    let waterDropBottomGap: CGFloat = 5.0
    let waterDropTopGap: CGFloat = 5.0
    let waterDropBottomRadius: CGFloat = 5.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        waterDropLayer = CAShapeLayer()
        waterDropLayer.fillColor = UIColor(red: 93.0/255.0, green: 162.0/255.0, blue: 0.0, alpha: 1.0).CGColor
        waterDropLayer.strokeColor = UIColor.clearColor().CGColor
        waterDropLayer.lineWidth = 0.5
        layer.addSublayer(waterDropLayer)
        
        indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White);
        indicator.center = CGPoint(x: frame.width/2.0, y: frame.height/2.0)
        indicator.hidesWhenStopped = true
        self.addSubview(indicator)
    }
   
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        if superview != nil && newSuperview == nil {
            let scrollView = self.superview as! UIScrollView
            if scrollView.showPullToRefresh && isObserving {
                scrollView.removeObserver(self, forKeyPath: "contentOffset")
                scrollView.removeObserver(self, forKeyPath: "contentSize")
                scrollView.removeObserver(self, forKeyPath: "frame")
                isObserving = false
            }
        }
    }
    
    func startAnimating() {
        if scrollView!.contentOffset.y == -scrollView!.contentInset.top {
            scrollView?.setContentOffset(CGPoint(x: scrollView!.contentOffset.x, y: -originalTopInset - frame.height), animated: true)
            wasTriggeredByUser = false
            breakWaterDrop()
        } else {
            wasTriggeredByUser = true
        }
        state = .Loading
        indicator.startAnimating()
    }
    
    func stopAnimating() {
        indicator.stopAnimating()
        if !wasTriggeredByUser {
            scrollView?.setContentOffset(CGPoint(x: scrollView!.contentOffset.x, y: -originalTopInset), animated: true)
        }
        state = .Stopped
    }
    
    /**
        线性插值
    */
    private func lerp(a: CGFloat, _ b: CGFloat, _ p: CGFloat) -> CGFloat {
        return a + (b - a) * p
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
            frame = CGRect(x: 0.0, y: -PullToRefreshViewHeight, width: scrollView?.frame.width ?? 0, height: PullToRefreshViewHeight)
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
                } else if offset.y >= scrollOffsetThreshold && state != .Stopped {
                    state = .Stopped
                } else if (scrollView!.dragging) {
                    // pulling down
                    if offset.y + originalTopInset > -(waterDropTopRadius * 2 + waterDropBottomGap + waterDropTopGap) {
                        // pulling before the whole balloon is shown
                        let center = CGPoint(x: bounds.width/2.0, y: bounds.height - waterDropBottomGap - waterDropTopRadius)
                        
                        indicator.center = center
                        
                        let path = UIBezierPath(arcCenter: center, radius: waterDropTopRadius, startAngle: 0.0, endAngle: CGFloat(2.0 * M_PI), clockwise: true)
                        waterDropLayer.path = path.CGPath
                    } else {
                        // pulling after the whole balloon is shown
                        let topY = bounds.height + offset.y + originalTopInset // top base line
                        if topY >= 0 {
                            // after the whole balloon is shown, stretch it
                            var bottomRadius = waterDropTopRadius * (topY / (bounds.height - (waterDropTopRadius * 2 + waterDropBottomGap + waterDropTopGap)))
                            bottomRadius = max(bottomRadius, waterDropBottomRadius)
                            
                            let path = UIBezierPath()
                            let topArcCenter = CGPoint(x: bounds.width/2.0, y: topY + waterDropTopGap + waterDropTopRadius)
                            
                            indicator.center = topArcCenter
                            
                            path.addArcWithCenter(topArcCenter, radius: waterDropTopRadius, startAngle: 0, endAngle: CGFloat(M_PI), clockwise: false)
                            
                            let bottomArcCenter = CGPoint(x: bounds.width/2.0, y: bounds.height - waterDropBottomGap - bottomRadius)
                            
                            let leftTopControlPoint = CGPoint(x: lerp(topArcCenter.x - waterDropTopRadius, bottomArcCenter.x - bottomRadius, 0.1), y: lerp(topArcCenter.y, bottomArcCenter.y, 0.5))
                            let leftBottomControlPoint = CGPoint(x: lerp(topArcCenter.x - waterDropTopRadius, bottomArcCenter.x - bottomRadius, 0.9), y: lerp(topArcCenter.y, bottomArcCenter.y, 0.5))
                            path.addCurveToPoint(CGPoint(x: bottomArcCenter.x - bottomRadius, y: bottomArcCenter.y), controlPoint1: leftTopControlPoint, controlPoint2: leftBottomControlPoint)
                            
                            path.addArcWithCenter(bottomArcCenter, radius: bottomRadius, startAngle: CGFloat(M_PI), endAngle: 0.0, clockwise: false)
                            
                            let rightTopControlPoint = CGPoint(x: lerp(topArcCenter.x + waterDropTopRadius, bottomArcCenter.x + bottomRadius, 0.1), y: lerp(topArcCenter.y, bottomArcCenter.y, 0.5))
                            let rightBottomControlPoint = CGPoint(x: lerp(topArcCenter.x + waterDropTopRadius, bottomArcCenter.x + bottomRadius, 0.9), y: lerp(topArcCenter.y, bottomArcCenter.y, 0.5))
                            path.addCurveToPoint(CGPoint(x: topArcCenter.x + waterDropTopRadius, y: topArcCenter.y), controlPoint1: rightBottomControlPoint, controlPoint2: rightTopControlPoint)
                            
                            path.closePath()
                            waterDropLayer.path = path.CGPath
                        } else {
                            // when top base line out of edge, break the balloon
                            breakWaterDrop()
                        }
                    }
                }
            } else {
                // loading
                var offset = max(scrollView!.contentOffset.y * -1, 0.0)
                offset = min(offset, originalTopInset + frame.height)
                let inset = scrollView!.contentInset
                scrollView?.contentInset = UIEdgeInsets(top: offset, left: inset.left, bottom: inset.bottom, right: inset.right)
            }
        }
    }
    
    private func breakWaterDrop() {
        let path = UIBezierPath()
        let topArcCenter = CGPoint(x: frame.width/2.0, y: waterDropTopGap + waterDropTopRadius)
        
        indicator.center = topArcCenter
        
        path.addArcWithCenter(topArcCenter, radius: waterDropTopRadius, startAngle: 0.0, endAngle: CGFloat(M_PI), clockwise: false)
        
        let bottomArcCenter = CGPoint(x: frame.width/2.0, y: frame.height - waterDropBottomGap - waterDropBottomRadius)
        let breakPoint = CGPoint(x: bottomArcCenter.x, y: bottomArcCenter.y - waterDropBottomRadius - 3.0)
        let leftControlPoint = CGPoint(x: topArcCenter.x - waterDropTopRadius, y: lerp(topArcCenter.y, breakPoint.y, 0.4))
        path.addQuadCurveToPoint(breakPoint, controlPoint: leftControlPoint)
        
        let rightControlPoint = CGPoint(x: topArcCenter.x + waterDropTopRadius, y: lerp(topArcCenter.y, breakPoint.y, 0.4))
        path.addQuadCurveToPoint(CGPoint(x: topArcCenter.x + waterDropTopRadius, y: topArcCenter.y), controlPoint: rightControlPoint)
        
        path.moveToPoint(bottomArcCenter)
        path.addArcWithCenter(bottomArcCenter, radius: waterDropBottomRadius, startAngle: 0.0, endAngle: CGFloat(2.0 * M_PI), clockwise: true)
        
        waterDropLayer.path = path.CGPath
    }
}

extension UIScrollView {
    private struct AssociatedKeys {
        static var DescriptiveName = "PullToRefresh"
    }
    
    dynamic var pullToRefreshView: PullToRefreshView {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.DescriptiveName) as! PullToRefreshView
        }
        
        set {
            willChangeValueForKey("pullToRefreshView")
            objc_setAssociatedObject(self, &AssociatedKeys.DescriptiveName, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_ASSIGN));
            didChangeValueForKey("pullToRefreshView")
        }
    }
    
    dynamic var showPullToRefresh: Bool {
        get {
            return !pullToRefreshView.hidden
        }
        
        set {
            pullToRefreshView.hidden = !newValue
            
            if newValue {
                if !pullToRefreshView.isObserving {
                    addObserver(pullToRefreshView, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.New, context: nil)
                    addObserver(pullToRefreshView, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.New, context: nil)
                    addObserver(pullToRefreshView, forKeyPath: "frame", options: NSKeyValueObservingOptions.New, context: nil)
                    pullToRefreshView.isObserving = true
                    pullToRefreshView.frame = CGRect(x: 0.0, y: -PullToRefreshViewHeight, width: frame.width, height: PullToRefreshViewHeight)
                }
            } else {
                if pullToRefreshView.isObserving {
                    removeObserver(pullToRefreshView, forKeyPath: "contentOffset")
                    removeObserver(pullToRefreshView, forKeyPath: "contentSize")
                    removeObserver(pullToRefreshView, forKeyPath: "frame")
                    pullToRefreshView.resetScrollViewContentInset()
                    pullToRefreshView.isObserving = false
                }
            }
        }
    }
        
    func addPullToRefreshWithActionHandler(actionHandler: () -> Void) {
//        if pullToRefreshView == nil {
            let view = PullToRefreshView(frame: CGRect(x: 0.0, y: -PullToRefreshViewHeight, width: frame.width, height: PullToRefreshViewHeight))
            view.clipsToBounds = true
            view.backgroundColor = UIColor.orangeColor()
            view.action = actionHandler
            view.scrollView = self
            view.originalTopInset = contentInset.top
            addSubview(view)
            pullToRefreshView = view
            showPullToRefresh = true
//        }
    }
    
    func triggerPullToRefresh() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.pullToRefreshView.state = .Triggered
            self.pullToRefreshView.startAnimating()
        })
    }
    
    func stopPullToRefresh() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.pullToRefreshView.state = .Stopped
            self.pullToRefreshView.stopAnimating()
        })
    }

}

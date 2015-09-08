//
//  UIScrollView+VCPullToRefresh.swift
//  VCPullToRefresh
//
//  Created by qihaijun on 9/1/15.
//  Copyright (c) 2015 VictorChee. All rights reserved.
//
//  Pull to refresh

import UIKit

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
        shapeLayer.fillColor = UIColor.orangeColor().CGColor
        shapeLayer.strokeColor = UIColor.clearColor().CGColor
        shapeLayer.lineWidth = 0.5
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
            if scrollView.enablePullToRefresh && isObserving {
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
            pullingAnimation(scrollView!.contentOffset)
        } else {
            wasTriggeredByUser = true
        }
        state = .Loading
        activityIndicatorView.startAnimating()
    }
    
    func stopAnimating() {
        activityIndicatorView.stopAnimating()
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
                    pullingAnimation(offset)
                } else if offset.y >= scrollOffsetThreshold && !scrollView!.dragging && state != .Stopped {
                    state = .Stopped
                } else if (scrollView!.dragging && state == .Stopped) {
                    // pulling down
                    pullingAnimation(offset)
                }
            }
        }
    }
    
    private func pullingAnimation(offset: CGPoint) {
        let waterDropTopRadius: CGFloat = 15.0
        let waterDropBottomGap: CGFloat = 5.0
        let waterDropTopGap: CGFloat = 5.0
        let waterDropBottomRadius: CGFloat = 5.0
        
        /**
        线性插值
        */
        func lerp(a: CGFloat, b: CGFloat, p: CGFloat) -> CGFloat {
            return a + (b - a) * p
        }
        
        func breakWaterDrop() {
            let path = UIBezierPath()
            let topArcCenter = CGPoint(x: frame.width/2.0, y: waterDropTopGap + waterDropTopRadius)
            
            activityIndicatorView.center = topArcCenter
            
            path.addArcWithCenter(topArcCenter, radius: waterDropTopRadius, startAngle: 0.0, endAngle: CGFloat(M_PI), clockwise: false)
            
            let bottomArcCenter = CGPoint(x: frame.width/2.0, y: frame.height - waterDropBottomGap - waterDropBottomRadius)
            let breakPoint = CGPoint(x: bottomArcCenter.x, y: bottomArcCenter.y - waterDropBottomRadius - 3.0)
            let leftControlPoint = CGPoint(x: topArcCenter.x - waterDropTopRadius, y: lerp(topArcCenter.y, breakPoint.y, 0.4))
            path.addQuadCurveToPoint(breakPoint, controlPoint: leftControlPoint)
            
            let rightControlPoint = CGPoint(x: topArcCenter.x + waterDropTopRadius, y: lerp(topArcCenter.y, breakPoint.y, 0.4))
            path.addQuadCurveToPoint(CGPoint(x: topArcCenter.x + waterDropTopRadius, y: topArcCenter.y), controlPoint: rightControlPoint)
            
            path.moveToPoint(bottomArcCenter)
            path.addArcWithCenter(bottomArcCenter, radius: waterDropBottomRadius, startAngle: 0.0, endAngle: CGFloat(2.0 * M_PI), clockwise: true)
            
            shapeLayer.path = path.CGPath
        }
        
        if state != .Stopped {
            breakWaterDrop()
        } else {
            // before triggered
            
            if offset.y + originalTopInset > -(waterDropTopRadius * 2 + waterDropBottomGap + waterDropTopGap) {
                // pulling before the whole balloon is shown
                let center = CGPoint(x: bounds.width/2.0, y: bounds.height - waterDropBottomGap - waterDropTopRadius)
                
                activityIndicatorView.center = center
                
                let path = UIBezierPath(arcCenter: center, radius: waterDropTopRadius, startAngle: 0.0, endAngle: CGFloat(2.0 * M_PI), clockwise: true)
                shapeLayer.path = path.CGPath
            } else {
                // pulling after the whole balloon is shown
                let topY = bounds.height + offset.y + originalTopInset // top base line
                if topY > 0 {
                    // after the whole balloon is shown, stretch it
                    var bottomRadius = waterDropTopRadius * (topY / (bounds.height - (waterDropTopRadius * 2 + waterDropBottomGap + waterDropTopGap)))
                    bottomRadius = max(bottomRadius, waterDropBottomRadius)
                    
                    let path = UIBezierPath()
                    let topArcCenter = CGPoint(x: bounds.width/2.0, y: topY + waterDropTopGap + waterDropTopRadius)
                    
                    activityIndicatorView.center = topArcCenter
                    
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
                    shapeLayer.path = path.CGPath
                } else {
                    // when top base line out of edge, it's already triggered
                }
            }
        }
    }
}

extension UIScrollView {
    private struct Constant {
        static var AssociatedKey = "PullToRefresh"
        static let PullToRefreshViewHeight: CGFloat = 60.0
    }
    
    dynamic var pullToRefreshView: PullToRefreshView {
        get {
            return objc_getAssociatedObject(self, &Constant.AssociatedKey) as! PullToRefreshView
        }
        
        set {
            willChangeValueForKey("pullToRefreshView")
            objc_setAssociatedObject(self, &Constant.AssociatedKey, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_ASSIGN));
            didChangeValueForKey("pullToRefreshView")
        }
    }
    
    dynamic var enablePullToRefresh: Bool {
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
                    pullToRefreshView.frame = CGRect(x: 0.0, y: -Constant.PullToRefreshViewHeight, width: frame.width, height: Constant.PullToRefreshViewHeight)
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
        let view = PullToRefreshView(frame: CGRect(x: 0.0, y: -Constant.PullToRefreshViewHeight, width: frame.width, height: Constant.PullToRefreshViewHeight))
        view.clipsToBounds = true
        view.action = actionHandler
        view.scrollView = self
        view.originalTopInset = contentInset.top
        addSubview(view)
        pullToRefreshView = view
        enablePullToRefresh = true
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

//
//  UIScrollView+PullToLoad.swift
//  VCPullToRefresh
//
//  Created by qihaijun on 9/1/15.
//  Copyright (c) 2015 VictorChee. All rights reserved.
//

import UIKit

class PullToLoadView: UIView {
    
    enum PullToLoadState {
        case Stopped
        case Triggered
        case Loading
    }
    
    var state: PullToLoadState = .Stopped {
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
    var activityIndicatorView: UIActivityIndicatorView!
    var action: (() -> Void)?
    var scrollView: UIScrollView?
    var originalBottomInset: CGFloat = 0.0
    var isObserving = false
    var wasTriggeredByUser = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White);
        activityIndicatorView.color = UIColor.orangeColor()
        activityIndicatorView.center = CGPoint(x: frame.width/2.0, y: frame.height/2.0)
        activityIndicatorView.hidesWhenStopped = true
        self.addSubview(activityIndicatorView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        if superview != nil && newSuperview == nil {
            let scrollView = self.superview as! UIScrollView
            if scrollView.enablePullToLoad && isObserving {
                scrollView.removeObserver(self, forKeyPath: "contentOffset")
                scrollView.removeObserver(self, forKeyPath: "contentSize")
                isObserving = false
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        activityIndicatorView.center = CGPoint(x: frame.width/2.0, y: frame.height/2.0)
    }
    
    func startAnimating() {
        if scrollView!.contentOffset.y == -scrollView!.contentInset.top {
            scrollView?.setContentOffset(CGPoint(x: scrollView!.contentOffset.x, y: originalBottomInset + frame.height - scrollView!.contentInset.top), animated: true)
            wasTriggeredByUser = false
        } else {
            wasTriggeredByUser = true
        }
        state = .Loading
        activityIndicatorView.startAnimating()
    }
    
    func stopAnimating() {
        activityIndicatorView.stopAnimating()
        state = .Stopped
    }
    
    private func resetScrollViewContentInset() {
        if var currentInsets = scrollView?.contentInset {
            currentInsets.bottom = originalBottomInset
            setScrollViewContentInset(currentInsets)
        }
    }
    
    private func setScrollViewContentInsetForLoading() {
        if var currentInsets = scrollView?.contentInset {
            currentInsets.bottom = originalBottomInset + frame.height
            setScrollViewContentInset(currentInsets)
        }
    }
    
    private func setScrollViewContentInset(insert: UIEdgeInsets) {
        UIView.animateWithDuration(0.75, delay: 0, options: [UIViewAnimationOptions.AllowUserInteraction, .BeginFromCurrentState], animations: { () -> Void in
            self.scrollView?.contentInset = insert
            if self.state == .Stopped {
                // finish animation
            }
            }) { (finished) -> Void in
                
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "contentOffset" {
            if let c = change {
                scrollViewDidScroll(c[NSKeyValueChangeNewKey]?.CGPointValue)
            }
        } else if keyPath == "contentSize" {
            frame = CGRect(x: 0.0, y: scrollView!.contentSize.height, width: scrollView?.frame.width ?? 0, height: frame.height)
            layoutSubviews()
        }
    }
    
    private func scrollViewDidScroll(contentOffset: CGPoint?) {
        if let offset = contentOffset {
            if state != .Loading {
                let scrollOffsetThreshold = scrollView!.contentSize.height - scrollView!.frame.height
                
                if !scrollView!.dragging && state == .Triggered {
                    state = .Loading
                    startAnimating()
                } else if offset.y > scrollOffsetThreshold && scrollView!.dragging && state == .Stopped {
                    state = .Triggered
                    activityIndicatorView.hidden = false
                } else if offset.y <= scrollOffsetThreshold && state != .Stopped {
                    state = .Stopped
                }
            }
        }
    }
}

extension UIScrollView {
    private struct Constant {
        static var AssociatedKey = "PullToLoad"
        static let PullToLoadViewHeight: CGFloat = 44.0
    }
    
    dynamic var pullToLoadView: PullToLoadView {
        get {
            return objc_getAssociatedObject(self, &Constant.AssociatedKey) as! PullToLoadView
        }
        
        set {
            willChangeValueForKey("pullToLoadView")
            objc_setAssociatedObject(self, &Constant.AssociatedKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN);
            didChangeValueForKey("pullToLoadView")
        }
    }
    
    dynamic var enablePullToLoad: Bool {
        get {
            return !pullToLoadView.hidden
        }
        
        set {
            pullToLoadView.hidden = !newValue
            
            if newValue {
                if !pullToLoadView.isObserving {
                    addObserver(pullToLoadView, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.New, context: nil)
                    addObserver(pullToLoadView, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.New, context: nil)
                    pullToLoadView.isObserving = true
                    pullToLoadView.frame = CGRect(x: 0.0, y: contentSize.height, width: frame.width, height: Constant.PullToLoadViewHeight)
                }
            } else {
                if pullToLoadView.isObserving {
                    removeObserver(pullToLoadView, forKeyPath: "contentOffset")
                    removeObserver(pullToLoadView, forKeyPath: "contentSize")
                    pullToLoadView.resetScrollViewContentInset()
                    pullToLoadView.isObserving = false
                }
            }
        }
    }
    
    func addPullToLoadWithActionHandler(actionHandler: () -> Void) {
        let view = PullToLoadView(frame: CGRect(x: 0.0, y: contentSize.height, width: frame.width, height: Constant.PullToLoadViewHeight))
        view.clipsToBounds = true
        view.action = actionHandler
        view.scrollView = self
        view.originalBottomInset = contentInset.bottom
        addSubview(view)
        pullToLoadView = view
        enablePullToLoad = true
    }
    
    func triggerPullToLoad() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.pullToLoadView.state = .Triggered
            self.pullToLoadView.startAnimating()
        })
    }
    
    func stopPullToLoad() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.pullToLoadView.state = .Stopped
            self.pullToLoadView.stopAnimating()
        })
    }
}
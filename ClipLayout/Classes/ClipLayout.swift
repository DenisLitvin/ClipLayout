//
//  LogView.swift
//  ClipLayout
//
//  Created by Denis Litvin on 09.06.2018.
//  Copyright © 2018 Denis Litvin. All rights reserved.
//

import UIKit

@objc
public enum ClipAlignment: Int {
    case head
    case tail
    case mid
    case stretch
}

@objc
public enum ClipDistribution: Int {
    case row
    case column
    case none
}

@objc
public class ClipPosition: NSObject {
    @objc public var vertical: ClipAlignment
    @objc public var horizontal: ClipAlignment
    
    @objc
    public init(vertical: ClipAlignment, horizontal: ClipAlignment) {
        self.vertical = vertical
        self.horizontal = horizontal
    }
}

@objc
public protocol ClipLayoutable {
    var sublayoutables: [ClipLayoutable] { get }
    var bounds: CGRect { get set }
    var frame: CGRect { get set }
    var clip: ClipLayout { get }
    
    func sizeThatFits(_ size: CGSize) -> CGSize
}


extension UIView: ClipLayoutable {
    
    public var sublayoutables: [ClipLayoutable] {
        return subviews
    }
}

extension CALayer: ClipLayoutable {
    
    public func sizeThatFits(_ size: CGSize) -> CGSize {
        return preferredFrameSize()
    }
    
    public var sublayoutables: [ClipLayoutable] {
        return sublayers ?? []
    }
}

@objc
public class ClipLayout: NSObject {
    private unowned let view: ClipLayoutable
    
    @objc public var enabled = false
    @objc public var cache: CGSize = .zero
    
    @objc public var alignment: ClipPosition = ClipPosition(vertical: .mid, horizontal: .mid)
    @objc public var insets = UIEdgeInsets.zero
    @objc public var wantsSize = CGSize.zero
    @objc public var distribution = ClipDistribution.none
    @objc public var supportRightToLeft = true
    
    @objc
    public init(with view: ClipLayoutable) {
        self.view = view
    }
    
    //MARK: - SWIFTY WAY TO CONFIGURE
    @discardableResult
    public func enable() -> Self {
        enabled = true
        return self
    }
    
    @discardableResult
    public func inset(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) -> ClipLayout {
        self.insets = UIEdgeInsetsMake(top, left, bottom, right)
        return self
    }
    
    @discardableResult
    public func inset(_ inset: CGFloat) -> ClipLayout {
        self.insets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        return self
    }
    
    @discardableResult
    public func insetLeft(_ inset: CGFloat) -> ClipLayout {
        self.insets.left = inset
        return self
    }
    
    @discardableResult
    public func insetRight(_ inset: CGFloat) -> ClipLayout {
        self.insets.right = inset
        return self
    }
    
    @discardableResult
    public func insetTop(_ inset: CGFloat) -> ClipLayout {
        self.insets.top = inset
        return self
    }
    
    @discardableResult
    public func insetBottom(_ inset: CGFloat) -> ClipLayout {
        self.insets.bottom = inset
        return self
    }
    
    @discardableResult
    public func withDistribution(_ distribution: ClipDistribution) -> ClipLayout {
        self.distribution = distribution
        return self
    }
    
    @discardableResult
    public func aligned(v: ClipAlignment, h: ClipAlignment) -> ClipLayout {
        self.alignment = ClipPosition(vertical: v, horizontal: h)
        return self
    }
    
    @discardableResult
    public func verticallyAligned(_ alignment: ClipAlignment) -> ClipLayout {
        self.alignment.vertical = alignment
        return self
    }
    
    @discardableResult
    public func horizontallyAligned(_ alignment: ClipAlignment) -> ClipLayout {
        self.alignment.horizontal = alignment
        return self
    }
    
    @discardableResult
    public func withSize(_ size: CGSize) -> ClipLayout {
        self.wantsSize = size
        return self
    }
    
    @discardableResult
    public func withHeight(_ height: CGFloat) -> ClipLayout {
        self.wantsSize.height = height
        return self
    }
    
    @discardableResult
    public func withWidth(_ width: CGFloat) -> ClipLayout {
        self.wantsSize.width = width
        return self
    }
    
    @discardableResult
    public func supportedRTL(_ supported: Bool) -> ClipLayout {
        self.supportRightToLeft = supported
        return self
    }
    
    //MARK: - LAYOUT
    @objc
    public func invalidateLayout() {
        layoutSubviews()
        view.sublayoutables
            .filter { $0.clip.enabled }
            .forEach { $0.clip.invalidateLayout() }
    }
    
    public func invalidateCache() {
        cache = .zero
        view.sublayoutables
            .filter { $0.clip.enabled }
            .forEach { $0.clip.cache = .zero }
    }
    
    @objc
    public func layoutSubviews() {
        let sizeBounds = view.bounds.size
        var subviews = view.sublayoutables
            .filter { $0.clip.enabled }
        let sizes = subviews
            .map { $0.clip.measureSize(within: sizeBounds) }
        
        if distribution == .none {
            for i in 0 ..< subviews.count {
                let size = sizes[i]
                let sub = subviews[i]
                let x = sub.clip.originX(width: size.width,
                                         within: sizeBounds.width)
                let y = sub.clip.originY(height: size.height,
                                         within: sizeBounds.height)
                sub.frame = CGRect(x: pixelRound(x),
                                   y: pixelRound(y),
                                   width: pixelRound(size.width),
                                   height: pixelRound(size.height))
            }
        }
        else if distribution == .column {
            let heights = trimmedHeights(for: subviews, within: sizeBounds)
            var lastY: CGFloat = 0
            
            for i in 0 ..< subviews.count {
                let sub = subviews[i]
                let size = sub.clip.measureSize(within: sizeBounds)
                let width = size.width
                let height = heights[i]
                
                let x = sub.clip.originX(width: width, within: sizeBounds.width)
                let y = lastY + sub.clip.insets.top
                lastY = y + height + sub.clip.insets.bottom
                
                sub.frame = CGRect(x: pixelRound(x),
                                   y: pixelRound(y),
                                   width: pixelRound(width),
                                   height: pixelRound(height))
            }
        }
        else if distribution == .row {
            var widths = trimmedWidths(for: subviews, within: sizeBounds)
            var lastX: CGFloat = 0
            
            if rightToLeftLanguage, supportRightToLeft {
                subviews.reverse()
                widths.reverse()
            }
            
            for i in 0 ..< subviews.count {
                let sub = subviews[i]
                let size = sub.clip.measureSize(within: sizeBounds)
                let height = size.height
                let width = widths[i]
                
                let x: CGFloat = lastX + sub.clip.insets.left
                let y = sub.clip.originY(height: height, within: sizeBounds.height)
                lastX = x + width + sub.clip.insets.right
                
                sub.frame = CGRect(x: pixelRound(x),
                                   y: pixelRound(y),
                                   width: pixelRound(width),
                                   height: pixelRound(height))
            }
        }
    }
    
    public func measureSize(within bounds: CGSize) -> CGSize {
        let width = measureWidth(within: bounds)
        let height = measureHeight(within: CGSize(width: width + insets.left + insets.right,
                                                  height: bounds.height))
        return CGSize(width: width, height: height)
    }
    
    //MARK: - PRIVATE
    
    //recursive check for stretch attribute
    private var verticallyStretched: Bool {
        return wantsSize.height == 0
            && (alignment.vertical == .stretch
                || view.sublayoutables
                    .filter { $0.clip.enabled }
                    .contains { $0.clip.verticallyStretched && $0.clip.wantsSize.height == 0 })
    }
    
    private var horizontallyStretched: Bool {
        return wantsSize.width == 0
            && (alignment.horizontal == .stretch
                || view.sublayoutables
                    .filter { $0.clip.enabled }
                    .contains { $0.clip.horizontallyStretched && $0.clip.wantsSize.width == 0 })
    }
    
    private var rightToLeftLanguage: Bool {
        return UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
    }
    
    private func pixelRound(_ value: CGFloat) -> CGFloat {
        let scale = Float(UIScreen.main.scale)
        let result = roundf(Float(value) * scale) / scale
        return CGFloat(result)
    }
    
    private func measureWidth(within sizeBounds: CGSize) -> CGFloat {
        var width: CGFloat = 0
        let sizeBounds = CGSize(width: sizeBounds.width - insets.left - insets.right,
                                height: sizeBounds.height - insets.top - insets.bottom)
        
        if cache.width != 0 { width = cache.width }
        else if wantsSize.width > 0 { width = wantsSize.width }
        else if horizontallyStretched { width = sizeBounds.width }
        else if distribution == .row {
            width = view.sublayoutables
                .filter { $0.clip.enabled }
                .reduce(0) { $0 + $1.clip.measureSize(within: sizeBounds).width
                    + $1.clip.insets.left
                    + $1.clip.insets.right
            }
        }
        else if distribution == .column {
            width = view.sublayoutables
                .filter { $0.clip.enabled }
                .map { $0.clip.measureSize(within: sizeBounds).width
                    + $0.clip.insets.left
                    + $0.clip.insets.right
                }
                .max() ?? 0
        }
        else {
            let size = view.sizeThatFits(sizeBounds)
            width = size.width
            if cache.height == 0 { cache.height = size.height }
        }
        if cache.width == 0 { cache.width = width }
        adjustForTextInputs(within: sizeBounds)
        return min(width, sizeBounds.width)
    }
    
    private func measureHeight(within sizeBounds: CGSize) -> CGFloat {
        var height: CGFloat = 0
        let sizeBounds = CGSize(width: sizeBounds.width - insets.left - insets.right,
                                height: sizeBounds.height - insets.top - insets.bottom)
        
        if cache.height != 0 { height = cache.height }
        else if wantsSize.height > 0 { height = wantsSize.height }
        else if verticallyStretched { height = sizeBounds.height }
        else if distribution == .column {
            height = view.sublayoutables
                .filter { $0.clip.enabled }
                .reduce(0, { $0 + $1.clip.measureSize(within: sizeBounds).height
                    + $1.clip.insets.top
                    + $1.clip.insets.bottom
                })
        }
        else if distribution == .row {
            height = view.sublayoutables
                .filter { $0.clip.enabled }
                .map { $0.clip.measureSize(within: sizeBounds).height
                    + $0.clip.insets.top
                    + $0.clip.insets.bottom
                }
                .max() ?? 0
        }
        else {
            let size = view.sizeThatFits(sizeBounds)
            height = size.height
            if cache.width == 0 {
                cache.width = size.width
            }
        }
        if cache.height == 0 { cache.height = height }
        adjustForTextInputs(within: sizeBounds)
        return min(height, sizeBounds.height)
    }
    
    private func adjustForTextInputs(within sizeBounds: CGSize) {
        //Allow view to adjust height if width will be trimmed
        //Primarily for UITextInput
        if distribution == .row {
            let subviews = view.sublayoutables.filter { $0.clip.enabled }
            let widths = trimmedWidths(for: subviews, within: sizeBounds)
            for i in 0 ..< subviews.count {
                subviews[i].clip.invalidateCache()
                subviews[i].clip.cache.width = widths[i]
            }
        }
    }
    
    private func trimmedHeights(for subviews: [ClipLayoutable], within size: CGSize) -> [CGFloat] {
        
        let stretchedIndices: [Int] = subviews
            .enumerated()
            .filter { $0.element.clip.verticallyStretched }
            .map { $0.offset }
        
        let heights: [CGFloat] = subviews
            .map { $0.clip.verticallyStretched ? 0 : $0.clip.measureSize(within: size).height }
        
        let accumulatedHeight: CGFloat = heights
            .reduce(0, +)
        
        let accumulatedPaddings: CGFloat = subviews
            .reduce(0) { $0 + $1.clip.insets.top + $1.clip.insets.bottom }
        
        return trim(values: heights,
                    stretchedIndices: stretchedIndices,
                    accumulatedValue: accumulatedHeight,
                    accumulatedPaddings: accumulatedPaddings,
                    limit: size.height)
    }
    
    private func trimmedWidths(for subviews: [ClipLayoutable], within sizeBounds: CGSize) -> [CGFloat] {
        let stretchedIndices: [Int] = subviews
            .enumerated()
            .filter { $0.element.clip.horizontallyStretched }
            .map { $0.offset }
        
        let widths: [CGFloat] = subviews
            .map { $0.clip.horizontallyStretched ? 0 : $0.clip.measureSize(within: sizeBounds).width }
        
        let accumulatedWidth: CGFloat = widths
            .reduce(0, +)
        
        let accumulatedPaddings: CGFloat = subviews
            .reduce(0) { $0 + $1.clip.insets.left + $1.clip.insets.right }
        
        return trim(values: widths,
                    stretchedIndices: stretchedIndices,
                    accumulatedValue: accumulatedWidth,
                    accumulatedPaddings: accumulatedPaddings,
                    limit: sizeBounds.width)
    }
    
    private func trim(values: [CGFloat],
                      stretchedIndices: [Int],
                      accumulatedValue: CGFloat,
                      accumulatedPaddings: CGFloat,
                      limit: CGFloat) -> [CGFloat] {
        var result: [CGFloat] = values
        
        //trim explicit size
        if accumulatedValue + accumulatedPaddings > limit {
            let totalPenalty = accumulatedValue + accumulatedPaddings - limit
            for i in 0 ..< values.count {
                let weight = values[i] / accumulatedValue
                let penalty = totalPenalty * weight
                result[i] = max(values[i] - penalty, 0)
            }
        }
            //trim stretched size
        else {
            let spaceLeft = (limit - accumulatedValue - accumulatedPaddings)
            let value = spaceLeft / CGFloat(stretchedIndices.count)
            stretchedIndices.forEach { result[$0] = value }
        }
        return result
    }
    
    private func originY(height: CGFloat, within limit: CGFloat) -> CGFloat {
        let y: CGFloat
        if alignment.vertical == .mid || verticallyStretched {
            y = midY(height: height, within: limit)
        }
        else if alignment.vertical == .head {
            y = insets.top
        }
        else {
            y = limit - height - insets.bottom
        }
        return y
    }
    
    private func midY(height: CGFloat, within limit: CGFloat) -> CGFloat {
        var y: CGFloat = 0
        y = (limit - height) / 2
        if y < insets.top {
            y = insets.top
        }
        if limit - height - y < insets.bottom {
            y = limit - height - insets.bottom
        }
        return y
    }
    
    private func originX(width: CGFloat, within limit: CGFloat) -> CGFloat {
        let x: CGFloat
        if alignment.horizontal == .mid || horizontallyStretched {
            x = midX(width: width, within: limit)
        }
        else if alignment.horizontal == .head {
            x = insets.left
        }
        else {
            x = limit - width - insets.right
        }
        return x
    }
    
    private func midX(width: CGFloat, within limit: CGFloat) -> CGFloat {
        var x: CGFloat = 0
        x = (limit - width) / 2
        if x < insets.left {
            x = insets.left
        }
        if limit - width - x < insets.right {
            x = limit - width - insets.right
        }
        return x
    }
}

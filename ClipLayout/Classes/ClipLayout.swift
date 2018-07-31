//
//  LogView.swift
//  ClipLayout
//
//  Created by Denis Litvin on 09.06.2018.
//  Copyright © 2018 Denis Litvin. All rights reserved.
//

import UIKit

public enum ClipAlignment {
    case head
    case tail
    case middle
    case stretch
}

public enum ClipPositioning {
    case row
    case column
    case none
}

@objc
public class ClipLayout: NSObject {
    private unowned let view: UIView
    
    @objc
    public var enabled = false
    @objc
    public var cache: CGSize = .zero
    
    public var verticalAlignment = ClipAlignment.middle
    public var horizontalAlignment = ClipAlignment.middle
    public var padding = UIEdgeInsets.zero
    public var wantsSize = CGSize.zero
    public var itemPositioning = ClipPositioning.none
    
    public var supportRightToLeft = true

    @objc
    public init(with view: UIView) {
        self.view = view
    }

    private var rightToLeftLanguage: Bool {
        return UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
    }
    
    //recursive check for stretch attribute
    private var verticallyStretched: Bool {
        return self.verticalAlignment == .stretch
            || self.view.subviews
                .filter { $0.clip.enabled }
                .map { $0.clip }
                .contains { $0!.verticallyStretched }
    }
    
    private var horizontallyStretched: Bool {
        return self.horizontalAlignment == .stretch
            || self.view.subviews
                .filter { $0.clip.enabled }
                .map { $0.clip }
                .contains { $0!.horizontallyStretched }
    }
    
    public func invalidateLayout() {
        layoutSubviews()
        view.subviews
            .filter { $0.clip.enabled }
            .forEach { $0.clip.invalidateLayout() }
    }
    
    public func invalidateCache() {
        cache = .zero
        view.subviews
            .filter { $0.clip.enabled }
            .forEach { $0.clip.cache = .zero }
    }
    
    @objc
    public func layoutSubviews() {
        let sizeBounds = self.view.bounds.size
        var subviews = view.subviews.filter { $0.clip.enabled }
        
        if itemPositioning == .none {
            for sub in subviews {
                let size = sub.clip.measureSize(within: sizeBounds)
                let width = size.width
                let height = size.height
                let x = sub.clip.originX(width: width, within: sizeBounds.width)
                let y = sub.clip.originY(height: height, within: sizeBounds.height)
                sub.frame = CGRect(origin: CGPoint(x: x, y: y), size: size)
            }
        }
        else if itemPositioning == .column {
            let heights = trimmedHeights(for: subviews, within: sizeBounds)
            var lastY: CGFloat = 0
            
            for i in 0 ..< subviews.count {
                let sub = subviews[i]
                let height = heights[i]
                let width = sub.clip.measureWidth(
                    within: CGSize(width: sizeBounds.width,
                                   height: height + sub.clip.padding.top + sub.clip.padding.bottom)
                )
                
                let x = sub.clip.originX(width: width, within: sizeBounds.width)
                let y: CGFloat = lastY + sub.clip.padding.top
                lastY = y + height + sub.clip.padding.bottom
                
                sub.frame = CGRect(x: x, y: y, width: width, height: height)
            }
        }
        else if itemPositioning == .row {
            var widths = trimmedWidths(for: subviews, within: sizeBounds)
            var lastX: CGFloat = 0
            
            if rightToLeftLanguage, supportRightToLeft{
                subviews.reverse()
                widths.reverse()
            }
            
            for i in 0 ..< subviews.count {
                let sub = subviews[i]
                let width = widths[i]
                let height = sub.clip.measureHeight(
                    within: CGSize(width: width + sub.clip.padding.left + sub.clip.padding.right,
                                   height: sizeBounds.height)
                )
                
                let x: CGFloat = lastX + sub.clip.padding.left
                let y = sub.clip.originY(height: height, within: sizeBounds.height)
                lastX = x + width + sub.clip.padding.right
                
                sub.frame = CGRect(x: x, y: y, width: width, height: height)
            }
        }
    }
    
    public func measureSize(within bounds: CGSize) -> CGSize {
        let width = measureWidth(within: bounds)
        let height = measureHeight(within: CGSize(width: width, height: bounds.height))
        return CGSize(width: width, height: height)
    }
    
    private func measureWidth(within bounds: CGSize) -> CGFloat {
        var width: CGFloat = 0
        let bounds = CGSize(width: bounds.width - padding.left - padding.right,
                            height: bounds.height - padding.top - padding.bottom)
        
        if cache.width != 0 { width = cache.width }
        else if horizontallyStretched { width = bounds.width }
        else if wantsSize.width > 0 { width = wantsSize.width }
        else if itemPositioning == .column || itemPositioning == .row {
            
            var max: CGFloat = 0
            var accumulated: CGFloat = 0
            for sub in view.subviews.filter({ $0.clip.enabled }) {
                let width = sub.clip.measureSize(within: bounds).width
                    + sub.clip.padding.left
                    + sub.clip.padding.right
                if itemPositioning == .column, width > max {
                    max = width
                } else {
                    accumulated += width
                }
            }
            width = itemPositioning == .row ? accumulated : max
        }
        else {
            let size = view.sizeThatFits(bounds)
            width = size.width
            cache.height = size.height
        }
        cache.width = width
        return min(width, bounds.width)
    }
    
    private func measureHeight(within bounds: CGSize) -> CGFloat {
        var height: CGFloat = 0
        let bounds = CGSize(width: bounds.width - padding.left - padding.right,
                            height: bounds.height - padding.top - padding.bottom)
        
        if cache.height != 0 { height = cache.height }
        else if verticallyStretched { height = bounds.height }
        else if wantsSize.height > 0 { height = wantsSize.height }
        else if itemPositioning == .column || itemPositioning == .row {
            
            var max: CGFloat = 0
            var accumulated: CGFloat = 0
            for sub in view.subviews.filter({ $0.clip.enabled }) {
                let height = sub.clip.measureSize(within: bounds).height
                    + sub.clip.padding.top
                    + sub.clip.padding.bottom
                if itemPositioning == .row, height > max {
                    max = height
                } else {
                    accumulated += height
                }
            }
            height = itemPositioning == .column ? accumulated : max
        }
        else {
            let size = view.sizeThatFits(bounds)
            height = size.height
            cache.width = size.width
        }
        cache.height = height
        return min(height, bounds.height)
    }
    
    private func trimmedHeights(for subviews: [UIView], within size: CGSize) -> [CGFloat] {
        var heights: [CGFloat] = Array(repeating: 0, count: subviews.count)
        
        let stretchedIndices: [Int] = subviews
            .enumerated()
            .filter { $0.element.clip.verticallyStretched }
            .map { $0.offset }
        
        let accumulatedHeight = subviews
            .enumerated()
            .filter { !$0.element.clip.verticallyStretched }
            .reduce(0) { (partial: CGFloat, model: (offset: Int, element: UIView)) -> CGFloat in
                let height = model.element.clip.measureHeight(within: size)
                heights[model.offset] = height
                return partial + height
        }
        
        let accumulatedPaddings = subviews
            .reduce(0) { $0 + $1.clip.padding.top + $1.clip.padding.bottom }
        
        return trim(values: heights,
                    stretchedIndices: stretchedIndices,
                    accumulatedValue: accumulatedHeight,
                    accumulatedPaddings: accumulatedPaddings,
                    limit: size.height)
    }
    
    private func trimmedWidths(for subviews: [UIView], within size: CGSize) -> [CGFloat] {
        var widths: [CGFloat] = Array(repeating: 0, count: subviews.count)
        
        let stretchedIndices: [Int] = subviews
            .enumerated()
            .filter { $0.element.clip.horizontallyStretched }
            .map { $0.offset }
        
        let accumulatedWidth = subviews
            .enumerated()
            .filter { !$0.element.clip.horizontallyStretched }
            .reduce(0) { (partial: CGFloat, model: (offset: Int, element: UIView)) -> CGFloat in
                let width = model.element.clip.measureWidth(within: size)
                widths[model.offset] = width
                return partial + width
        }

        let accumulatedPaddings = subviews
            .reduce(0) { $0 + $1.clip.padding.left + $1.clip.padding.right }
        
        return trim(values: widths,
             stretchedIndices: stretchedIndices,
             accumulatedValue: accumulatedWidth,
             accumulatedPaddings: accumulatedPaddings,
             limit: size.width)
    }
    
    private func trim(values: [CGFloat],
                      stretchedIndices: [Int],
                      accumulatedValue: CGFloat,
                      accumulatedPaddings: CGFloat,
                      limit: CGFloat) -> [CGFloat] {
        var result: [CGFloat] = values

        if accumulatedValue + accumulatedPaddings > limit {
            let penalty = accumulatedValue + accumulatedPaddings - limit
            for i in 0 ..< values.count {
                result[i] = max(values[i] - penalty * values[i] / accumulatedValue, 0)
            }
        }
        else {
            let spaceLeft = (limit - accumulatedValue - accumulatedPaddings) / CGFloat(stretchedIndices.count)
            stretchedIndices.forEach { result[$0] = spaceLeft }
        }
        return result
    }
    
    private func originY(height: CGFloat, within limit: CGFloat) -> CGFloat {
        let y: CGFloat
        if verticalAlignment == .middle || verticallyStretched {
            y = midY(height: height, within: limit)
        }
        else if verticalAlignment == .head {
            y = padding.top
        }
        else {
            y = limit - height - padding.bottom
        }
        return y
    }
    
    private func midY(height: CGFloat, within limit: CGFloat) -> CGFloat {
        var y: CGFloat = 0
        y = (limit - height) / 2
        if y < padding.top {
            y = padding.top
        }
        if limit - height - y < padding.bottom {
            y = limit - height - padding.bottom
        }
        return y
    }
    
    private func originX(width: CGFloat, within limit: CGFloat) -> CGFloat {
        let x: CGFloat
        if horizontalAlignment == .middle || horizontallyStretched {
            x = midX(width: width, within: limit)
        }
        else if horizontalAlignment == .head {
            x = padding.left
        }
        else {
            x = limit - width - padding.right
        }
        return x
    }
    
    private func midX(width: CGFloat, within limit: CGFloat) -> CGFloat {
        var x: CGFloat = 0
        x = (limit - width) / 2
        if x < padding.left {
            x = padding.left
        }
        if limit - width - x < padding.right {
            x = limit - width - padding.right
        }
        return x
    }
}

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
    case mid
    case stretch
}

public enum ClipDistribution {
    case row
    case column
    case none
}

public struct ClipPosition {
    var vertical: ClipAlignment
    var horizontal: ClipAlignment
}

@objc
public class ClipLayout: NSObject {
    private unowned let view: UIView
    
    @objc
    public var enabled = false
    @objc
    public var cache: CGSize = .zero
    
    public var alignment: ClipPosition = ClipPosition(vertical: .mid, horizontal: .mid)
    public var padding = UIEdgeInsets.zero
    public var wantsSize = CGSize.zero
    public var itemPositioning = ClipDistribution.none
    
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
                .contains { $0.clip.verticallyStretched }
    }
    
    private var horizontallyStretched: Bool {
        return self.horizontalAlignment == .stretch
            || self.view.subviews
                .filter { $0.clip.enabled }
                .contains { $0.clip.horizontallyStretched }
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
    
    public func layoutSubviews() {
        let sizeBounds = view.bounds.size
        var subviews = view.subviews
            .filter { $0.clip.enabled }
        let sizes = subviews
            .map { $0.clip.measureSize(within: sizeBounds) }
        
        if itemPositioning == .none {
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
        else if itemPositioning == .column {
            let heights = trimmedHeights(for: subviews, within: sizeBounds)
            var lastY: CGFloat = 0
            
            for i in 0 ..< subviews.count {
                let sub = subviews[i]
                let size = sub.clip.measureSize(within: sizeBounds)
                let width = size.width
                let height = heights[i]
                
                let x = sub.clip.originX(width: width, within: sizeBounds.width)
                let y = lastY + sub.clip.padding.top
                lastY = y + height + sub.clip.padding.bottom
                
                sub.frame = CGRect(x: pixelRound(x),
                                   y: pixelRound(y),
                                   width: pixelRound(width),
                                   height: pixelRound(height))
            }
        }
        else if itemPositioning == .row {
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
                
                let x: CGFloat = lastX + sub.clip.padding.left
                let y = sub.clip.originY(height: height, within: sizeBounds.height)
                lastX = x + width + sub.clip.padding.right
                
                sub.frame = CGRect(x: pixelRound(x),
                                   y: pixelRound(y),
                                   width: pixelRound(width),
                                   height: pixelRound(height))
            }
        }
    }
    
    public func measureSize(within bounds: CGSize) -> CGSize {
        let width = measureWidth(within: bounds)
        let height = measureHeight(within: CGSize(width: width + padding.left + padding.right,
                                                  height: bounds.height))
        return CGSize(width: width, height: height)
    }
    
    //MARK: - PRIVATE
    
    private func pixelRound(_ value: CGFloat) -> CGFloat {
        let scale = Float(UIScreen.main.scale)
        let result = roundf(Float(value) * scale) / scale
        return CGFloat(result)
    }
    
    private func measureWidth(within size: CGSize) -> CGFloat {
        var width: CGFloat = 0
        let size = CGSize(width: size.width - padding.left - padding.right,
                            height: size.height - padding.top - padding.bottom)
        
        if cache.width != 0 { width = cache.width }
        else if horizontallyStretched { width = size.width }
        else if wantsSize.width > 0 { width = wantsSize.width }
        else if itemPositioning == .column || itemPositioning == .row {
            
            var max: CGFloat = 0
            var accumulated: CGFloat = 0
            let subviews = view.subviews.filter { $0.clip.enabled }

            for sub in subviews {
                let width = sub.clip.measureSize(within: size).width
                    + sub.clip.padding.left
                    + sub.clip.padding.right
                if itemPositioning == .column, width > max {
                    max = width
                } else {
                    accumulated += width
                }
            }
            if itemPositioning == .row {
                let widths = trimmedWidths(for: subviews, within: size)
                for i in 0 ..< subviews.count {
                    subviews[i].clip.cache.width = widths[i]
                }
            }
            width = itemPositioning == .row ? accumulated : max
        }
        else {
            let size = view.sizeThatFits(size)
            width = size.width
            cache.height = size.height
        }
        cache.width = width
        return min(width, size.width)
    }
    
    private func measureHeight(within size: CGSize) -> CGFloat {
        var height: CGFloat = 0
        let size = CGSize(width: size.width - padding.left - padding.right,
                            height: size.height - padding.top - padding.bottom)
        
        if cache.height != 0 { height = cache.height }
        else if verticallyStretched { height = size.height }
        else if wantsSize.height > 0 { height = wantsSize.height }
        else if itemPositioning == .column || itemPositioning == .row {
            
            var max: CGFloat = 0
            var accumulated: CGFloat = 0
            for sub in view.subviews.filter({ $0.clip.enabled }) {
                let height = sub.clip.measureSize(within: size).height
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
            let size = view.sizeThatFits(size)
            height = size.height
            cache.width = size.width
        }
        cache.height = height
        return min(height, size.height)
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

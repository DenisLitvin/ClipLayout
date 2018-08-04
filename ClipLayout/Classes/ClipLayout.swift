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
    public var vertical: ClipAlignment
    public var horizontal: ClipAlignment
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
    
    //recursive check for stretch attribute
    private var verticallyStretched: Bool {
        return wantsSize.height == 0
            && (alignment.vertical == .stretch
                || view.subviews
                    .filter { $0.clip.enabled }
                    .contains { $0.clip.verticallyStretched && $0.clip.wantsSize.height == 0 })
    }
    
    private var horizontallyStretched: Bool {
        return wantsSize.width == 0
            && (alignment.horizontal == .stretch
                || view.subviews
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
        let sizeBounds = CGSize(width: sizeBounds.width - padding.left - padding.right,
                                height: sizeBounds.height - padding.top - padding.bottom)
        
        if cache.width != 0 { width = cache.width }
        else if wantsSize.width > 0 { width = wantsSize.width }
        else if horizontallyStretched { width = sizeBounds.width }
        else if itemPositioning == .row {
            width = view.subviews
                .filter { $0.clip.enabled }
                .reduce(0) { $0 + $1.clip.measureSize(within: sizeBounds).width
                    + $1.clip.padding.left
                    + $1.clip.padding.right
            }
        }
        else if itemPositioning == .column {
            width = view.subviews
                .filter { $0.clip.enabled }
                .map { $0.clip.measureSize(within: sizeBounds).width
                    + $0.clip.padding.left
                    + $0.clip.padding.right
                }
                .max() ?? 0
        }
        else {
            let size = view.sizeThatFits(sizeBounds)
            width = size.width
            if cache.height == 0 { cache.height = size.height }
        }
        if cache.width == 0 { cache.width = width }
        
        //Allow view to adjust hight if width will be trimmed
        //Primarily for UITextInput
        if itemPositioning == .row {
            let subviews = view.subviews.filter { $0.clip.enabled }
            let widths = trimmedWidths(for: subviews, within: sizeBounds)
            for i in 0 ..< subviews.count {
                subviews[i].clip.invalidateCache()
                subviews[i].clip.cache.width = widths[i]
            }
        }
        return min(width, sizeBounds.width)
    }
    
    private func measureHeight(within sizeBounds: CGSize) -> CGFloat {
        var height: CGFloat = 0
        let sizeBounds = CGSize(width: sizeBounds.width - padding.left - padding.right,
                                height: sizeBounds.height - padding.top - padding.bottom)
        
        if cache.height != 0 { height = cache.height }
        else if wantsSize.height > 0 { height = wantsSize.height }
        else if verticallyStretched { height = sizeBounds.height }
        else if itemPositioning == .column {
            height = view.subviews
                .filter { $0.clip.enabled }
                .reduce(0, { $0 + $1.clip.measureSize(within: sizeBounds).height
                    + $1.clip.padding.top
                    + $1.clip.padding.bottom
                })
        }
        else if itemPositioning == .row {
            height = view.subviews
                .filter { $0.clip.enabled }
                .map { $0.clip.measureSize(within: sizeBounds).height
                    + $0.clip.padding.top
                    + $0.clip.padding.bottom
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
        if cache.height == 0 {
            cache.height = height
        }
        return min(height, sizeBounds.height)
    }
    
    
    private func trimmedHeights(for subviews: [UIView], within size: CGSize) -> [CGFloat] {
        
        let stretchedIndices: [Int] = subviews
            .enumerated()
            .filter { $0.element.clip.verticallyStretched }
            .map { $0.offset }
        
        let heights: [CGFloat] = subviews
            .map { $0.clip.verticallyStretched ? 0 : $0.clip.measureSize(within: size).height }
        
        let accumulatedHeight: CGFloat = heights
            .reduce(0, +)
        
        let accumulatedPaddings: CGFloat = subviews
            .reduce(0) { $0 + $1.clip.padding.top + $1.clip.padding.bottom }
        
        return trim(values: heights,
                    stretchedIndices: stretchedIndices,
                    accumulatedValue: accumulatedHeight,
                    accumulatedPaddings: accumulatedPaddings,
                    limit: size.height)
    }
    
    private func trimmedWidths(for subviews: [UIView], within sizeBounds: CGSize) -> [CGFloat] {
        let stretchedIndices: [Int] = subviews
            .enumerated()
            .filter { $0.element.clip.horizontallyStretched }
            .map { $0.offset }
        
        let widths: [CGFloat] = subviews
            .map { $0.clip.horizontallyStretched ? 0 : $0.clip.measureSize(within: sizeBounds).width }
        
        let accumulatedWidth: CGFloat = widths
            .reduce(0, +)
        
        let accumulatedPaddings: CGFloat = subviews
            .reduce(0) { $0 + $1.clip.padding.left + $1.clip.padding.right }
        
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
        if alignment.horizontal == .mid || horizontallyStretched {
            x = midX(width: width, within: limit)
        }
        else if alignment.horizontal == .head {
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

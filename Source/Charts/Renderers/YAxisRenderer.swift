//
//  YAxisRenderer.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

#if canImport(UIKit)
    import UIKit
#endif

#if canImport(Cocoa)
import Cocoa
#endif

@objc(ChartYAxisRenderer)
open class YAxisRenderer: AxisRendererBase
{
    @objc public init(viewPortHandler: ViewPortHandler, yAxis: YAxis?, transformer: Transformer?)
    {
        super.init(viewPortHandler: viewPortHandler, transformer: transformer, axis: yAxis)
    }
    
    /// draws the y-axis labels to the screen
    open override func renderAxisLabels(context: CGContext)
    {
        guard let yAxis = self.axis as? YAxis else { return }
        
        if !yAxis.isEnabled || !yAxis.isDrawLabelsEnabled
        {
            return
        }
        
        let xoffset = yAxis.xOffset
        let yoffset = yAxis.labelFont.lineHeight / 2.5 + yAxis.yOffset
        
        let dependency = yAxis.axisDependency
        let labelPosition = yAxis.labelPosition
        
        var xPos = CGFloat(0.0)
        
        var textAlign: NSTextAlignment
        
        if dependency == .left
        {
            if labelPosition == .outsideChart
            {
                textAlign = .right
                xPos = viewPortHandler.offsetLeft - xoffset
            }
            else
            {
                textAlign = .left
                xPos = viewPortHandler.offsetLeft + xoffset
            }
            
        }
        else
        {
            if labelPosition == .outsideChart
            {
                textAlign = .left
                xPos = viewPortHandler.contentRight + xoffset
            }
            else
            {
                textAlign = .right
                xPos = viewPortHandler.contentRight - xoffset
            }
        }
        
        drawYLabels(
            context: context,
            fixedPosition: xPos,
            positions: transformedPositions(),
            offset: yoffset - yAxis.labelFont.lineHeight,
            textAlign: textAlign)
    }
    
    open override func renderAxisLine(context: CGContext)
    {
        guard let yAxis = self.axis as? YAxis else { return }
        
        if !yAxis.isEnabled || !yAxis.drawAxisLineEnabled
        {
            return
        }
        
        context.saveGState()
        
        context.setStrokeColor(yAxis.axisLineColor.cgColor)
        context.setLineWidth(yAxis.axisLineWidth)
        if yAxis.axisLineDashLengths != nil
        {
            context.setLineDash(phase: yAxis.axisLineDashPhase, lengths: yAxis.axisLineDashLengths)
        }
        else
        {
            context.setLineDash(phase: 0.0, lengths: [])
        }
        
        if yAxis.axisDependency == .left
        {
            context.beginPath()
            context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentTop))
            context.addLine(to: CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentBottom))
            context.strokePath()
        }
        else
        {
            context.beginPath()
            context.move(to: CGPoint(x: viewPortHandler.contentRight, y: viewPortHandler.contentTop))
            context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: viewPortHandler.contentBottom))
            context.strokePath()
        }
        
        context.restoreGState()
    }
    
    /// draws the y-labels on the specified x-position
    open func drawYLabels(
        context: CGContext,
        fixedPosition: CGFloat,
        positions: [CGPoint],
        offset: CGFloat,
        textAlign: NSTextAlignment)
    {
        guard
            let yAxis = self.axis as? YAxis
            else { return }
        
        let labelFont = yAxis.labelFont
        let labelTextColor = yAxis.labelTextColor
        
        let from = yAxis.isDrawBottomYLabelEntryEnabled ? 0 : 1
        let to = yAxis.isDrawTopYLabelEntryEnabled ? yAxis.entryCount : (yAxis.entryCount - 1)
        
        let xOffset = yAxis.labelXOffset
        
        for i in stride(from: from, to: to, by: 1)
        {
            let text = yAxis.getFormattedLabel(i)
            
            ChartUtils.drawText(
                context: context,
                text: text,
                point: CGPoint(x: fixedPosition + xOffset, y: positions[i].y + offset),
                align: textAlign,
                attributes: [.font: labelFont, .foregroundColor: labelTextColor]
            )
        }
    }
    
    open override func renderGridLines(context: CGContext)
    {
        guard let
            yAxis = self.axis as? YAxis
            else { return }
        
        if !yAxis.isEnabled
        {
            return
        }
        
        if yAxis.drawRiskLeveAreaEnabled {
            // draw RiskLeveArea
            drawRiskLeveArea(context: context)
        }
        
        if yAxis.drawGridLinesEnabled
        {
            let positions = transformedPositions()
            
            context.saveGState()
            defer { context.restoreGState() }
            context.clip(to: self.gridClippingRect)
            
            context.setShouldAntialias(yAxis.gridAntialiasEnabled)
            context.setStrokeColor(yAxis.gridColor.cgColor)
            context.setLineWidth(yAxis.gridLineWidth)
            context.setLineCap(yAxis.gridLineCap)
            
            if yAxis.gridLineDashLengths != nil
            {
                context.setLineDash(phase: yAxis.gridLineDashPhase, lengths: yAxis.gridLineDashLengths)
                
            }
            else
            {
                context.setLineDash(phase: 0.0, lengths: [])
            }
            
            // draw the grid
            positions.forEach { drawGridLine(context: context, position: $0) }
        }

        if yAxis.drawZeroLineEnabled
        {
            // draw zero line
            drawZeroLine(context: context)
        }
    }
    
    /// Draws the RiskLeveArea.
    @objc open func drawRiskLeveArea(context: CGContext)
    {
        guard
            let yAxis = self.axis as? YAxis,
            let transformer = self.transformer
            else { return }
        
        // 要找出的范围
        var targetRange = [NSDictionary]()//数据落到的目标范围
        
        //找出最低下限范围
        for minRange in yAxis.riskLevelAreaArray {
            let lower_limit = (minRange["left_closed"] as! NSString).doubleValue
            if yAxis.leftAxis_ValueMin >= lower_limit {
                targetRange.append(minRange)
                break
            } else {
                targetRange.append(minRange)
            }
        }
        
        //找最高上限范围
        for maxRange in targetRange {
            let upper_limit = (maxRange["left_closed"] as! NSString).doubleValue
            if yAxis.leftAxis_ValueMax > upper_limit {
                break
            } else {
                targetRange.removeFirst()
            }
        }
        
        //颜色数组
        let colors = [0x2ECC71,0x3498DB,0xFFDD26,0xE67E22,0xCE2029]

        let pixel_ZeroPoint = CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentTop)// 顶点 0 点 的实际坐标
        let pixel_MaxPoint = CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentBottom)// 最底边 的实际坐标

        for index in 0..<targetRange.count {
            
            var lastIndex = index - 1; if lastIndex == -1 { lastIndex = 0 }
            let lase_closeValue = (targetRange[lastIndex]["left_closed"] as! NSString).doubleValue
            
            let closeValue = (targetRange[index]["left_closed"] as! NSString).doubleValue
            let closeAreaName = targetRange[index]["areaName"] as! String
            
            let color = targetRange[index]["colorIndex"] as! String
            let colorIndex = Int(color)!

            // 分界点 左闭右开 ::: 20 ====> [20,+）
            var pixel_lastPoint = CGPoint(x: 0.0, y: lase_closeValue).applying(transformer.valueToPixelMatrix)
            var pixel_Point = CGPoint(x: 0.0, y: closeValue).applying(transformer.valueToPixelMatrix)
            
            if index == 0 {
                pixel_lastPoint = pixel_ZeroPoint
            }
            
            if index == (targetRange.count - 1) {
                pixel_Point = pixel_MaxPoint
            }
            
            drawRiskArea_LevelCustom(context: context, y: pixel_lastPoint.y, height: pixel_Point.y - pixel_lastPoint.y, string: closeAreaName, rgbHexValue: UInt32(colors[colorIndex]))
        }
    }
    
    // draw Custom  risk level area
    func drawRiskArea_LevelCustom(context: CGContext, y : CGFloat, height : CGFloat, string: String, rgbHexValue:UInt32) {
        let rect = CGRect(x: viewPortHandler.contentLeft, y: y, width: viewPortHandler.contentRight - viewPortHandler.contentLeft, height: height)
        drawUnitRiskAreaWithRect(context: context, rect: rect, string: string, rgbHexValue: rgbHexValue)
    }
    
    // draw unit risklevel
    func drawUnitRiskAreaWithRect(context: CGContext, rect : CGRect, string: String, rgbHexValue:UInt32) {
        let color = colorByHex(rgbHexValue: rgbHexValue, alpha: 0.24);
        context.setFillColor(color.cgColor)
        context.addRect(rect)
        context.drawPath(using: .fill)
        
        drawRotatedText(string, at: CGPoint(x: viewPortHandler.contentRight * 0.2, y: rect.origin.y + rect.size.height / 2.0), angle: -30, font: UIFont(name: "HelveticaNeue-Bold", size: 14)!, color: colorByHex(rgbHexValue: 0x000000, alpha: 0.14))
        drawRotatedText(string, at: CGPoint(x: viewPortHandler.contentRight / 2.0, y: rect.origin.y + rect.size.height / 2.0), angle: -30, font: UIFont(name: "HelveticaNeue-Bold", size: 14)!, color: colorByHex(rgbHexValue: 0x000000, alpha: 0.14))
        drawRotatedText(string, at: CGPoint(x: viewPortHandler.contentRight * 0.8, y: rect.origin.y + rect.size.height / 2.0), angle: -30, font: UIFont(name: "HelveticaNeue-Bold", size: 14)!, color: colorByHex(rgbHexValue: 0x000000, alpha: 0.14))
    }
    
    // hex color
    func colorByHex(rgbHexValue:UInt32, alpha:Double = 1.0) -> UIColor {
        let red = Double((rgbHexValue & 0xFF0000) >> 16) / 256.0
        let green = Double((rgbHexValue & 0xFF00) >> 8) / 256.0
        let blue = Double((rgbHexValue & 0xFF)) / 256.0

        return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
    
    // draw Rotated Text
    func drawRotatedText(_ text: String, at p: CGPoint, angle: CGFloat, font: UIFont, color: UIColor) {
        // Draw text centered on the point, rotated by an angle in degrees moving clockwise.
        let attrs = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color]
        let textSize = text.size(withAttributes: attrs)
        let c = UIGraphicsGetCurrentContext()!
        c.saveGState()
        // Translate the origin to the drawing location and rotate the coordinate system.
        c.translateBy(x: p.x, y: p.y)
        c.rotate(by: angle * .pi / 180)
        // Draw the text centered at the point.
        text.draw(at: CGPoint(x: -textSize.width / 2, y: -textSize.height / 2), withAttributes: attrs)
        // Restore the original coordinate system.
        c.restoreGState()
    }
    
    @objc open var gridClippingRect: CGRect
    {
        var contentRect = viewPortHandler.contentRect
        let dy = self.axis?.gridLineWidth ?? 0.0
        contentRect.origin.y -= dy / 2.0
        contentRect.size.height += dy
        return contentRect
    }
    
    @objc open func drawGridLine(
        context: CGContext,
        position: CGPoint)
    {
        context.beginPath()
        context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: position.y))
        context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: position.y))
        context.strokePath()
    }
    
    @objc open func transformedPositions() -> [CGPoint]
    {
        guard
            let yAxis = self.axis as? YAxis,
            let transformer = self.transformer
            else { return [CGPoint]() }
        
        var positions = [CGPoint]()
        positions.reserveCapacity(yAxis.entryCount)
        
        let entries = yAxis.entries
        
        for i in stride(from: 0, to: yAxis.entryCount, by: 1)
        {
            positions.append(CGPoint(x: 0.0, y: entries[i]))
        }

        transformer.pointValuesToPixel(&positions)
        
        return positions
    }

    /// Draws the zero line at the specified position.
    @objc open func drawZeroLine(context: CGContext)
    {
        guard
            let yAxis = self.axis as? YAxis,
            let transformer = self.transformer,
            let zeroLineColor = yAxis.zeroLineColor
            else { return }
        
        context.saveGState()
        defer { context.restoreGState() }
        
        var clippingRect = viewPortHandler.contentRect
        clippingRect.origin.y -= yAxis.zeroLineWidth / 2.0
        clippingRect.size.height += yAxis.zeroLineWidth
        context.clip(to: clippingRect)

        context.setStrokeColor(zeroLineColor.cgColor)
        context.setLineWidth(yAxis.zeroLineWidth)
        
        let pos = transformer.pixelForValues(x: 0.0, y: 0.0)
    
        if yAxis.zeroLineDashLengths != nil
        {
            context.setLineDash(phase: yAxis.zeroLineDashPhase, lengths: yAxis.zeroLineDashLengths!)
        }
        else
        {
            context.setLineDash(phase: 0.0, lengths: [])
        }
        
        context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: pos.y))
        context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: pos.y))
        context.drawPath(using: CGPathDrawingMode.stroke)
    }
    
    open override func renderLimitLines(context: CGContext)
    {
        guard
            let yAxis = self.axis as? YAxis,
            let transformer = self.transformer
            else { return }
        
        let limitLines = yAxis.limitLines
        
        if limitLines.count == 0
        {
            return
        }
        
        context.saveGState()
        
        let trans = transformer.valueToPixelMatrix
        
        var position = CGPoint(x: 0.0, y: 0.0)
        
        for i in 0 ..< limitLines.count
        {
            let l = limitLines[i]
            
            if !l.isEnabled
            {
                continue
            }
            
            context.saveGState()
            defer { context.restoreGState() }
            
            var clippingRect = viewPortHandler.contentRect
            clippingRect.origin.y -= l.lineWidth / 2.0
            clippingRect.size.height += l.lineWidth
            context.clip(to: clippingRect)
            
            position.x = 0.0
            position.y = CGFloat(l.limit)
            position = position.applying(trans)
            
            context.beginPath()
            context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: position.y))
            context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: position.y))
            
            context.setStrokeColor(l.lineColor.cgColor)
            context.setLineWidth(l.lineWidth)
            if l.lineDashLengths != nil
            {
                context.setLineDash(phase: l.lineDashPhase, lengths: l.lineDashLengths!)
            }
            else
            {
                context.setLineDash(phase: 0.0, lengths: [])
            }
            
            context.strokePath()
            
            let label = l.label
            
            // if drawing the limit-value label is enabled
            if l.drawLabelEnabled && label.count > 0
            {
                let labelLineHeight = l.valueFont.lineHeight
                
                let xOffset: CGFloat = 4.0 + l.xOffset
                let yOffset: CGFloat = l.lineWidth + labelLineHeight + l.yOffset
                
                if l.labelPosition == .topRight
                {
                    ChartUtils.drawText(context: context,
                        text: label,
                        point: CGPoint(
                            x: viewPortHandler.contentRight - xOffset,
                            y: position.y - yOffset),
                        align: .right,
                        attributes: [NSAttributedString.Key.font: l.valueFont, NSAttributedString.Key.foregroundColor: l.valueTextColor])
                }
                else if l.labelPosition == .bottomRight
                {
                    ChartUtils.drawText(context: context,
                        text: label,
                        point: CGPoint(
                            x: viewPortHandler.contentRight - xOffset,
                            y: position.y + yOffset - labelLineHeight),
                        align: .right,
                        attributes: [NSAttributedString.Key.font: l.valueFont, NSAttributedString.Key.foregroundColor: l.valueTextColor])
                }
                else if l.labelPosition == .topLeft
                {
                    ChartUtils.drawText(context: context,
                        text: label,
                        point: CGPoint(
                            x: viewPortHandler.contentLeft + xOffset,
                            y: position.y - yOffset),
                        align: .left,
                        attributes: [NSAttributedString.Key.font: l.valueFont, NSAttributedString.Key.foregroundColor: l.valueTextColor])
                }
                else
                {
                    ChartUtils.drawText(context: context,
                        text: label,
                        point: CGPoint(
                            x: viewPortHandler.contentLeft + xOffset,
                            y: position.y + yOffset - labelLineHeight),
                        align: .left,
                        attributes: [NSAttributedString.Key.font: l.valueFont, NSAttributedString.Key.foregroundColor: l.valueTextColor])
                }
            }
        }
        
        context.restoreGState()
    }
}

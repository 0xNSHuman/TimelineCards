//
//  TimelineCard.swift
//  Created by Vladislav Averin on 07/11/2017.

/*
The MIT License (MIT)

Copyright © 2017 Vladislav Averin

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import UIKit
import CoreGraphics

/// All elements making up timeline source must comply with this protocol

public protocol TimelineSourceElement {
	var id: UUID { get }
	
	var milestoneShape: TimelineCard.ItemShape { get set }
	
	var title: NSAttributedString? { get set }
	var subtitle: NSAttributedString? { get set }
	var customView: UIView? { get set }
	var icon: UIImage? { get set }
	
	var subelements: [TimelineSourceElement]? { get set }
}

/// Data source objects should implement this protocol

public protocol TimelineCardDataProvider {
	func elementsForTimelineCard(_ timelineCard: TimelineCard,
	                             containerWidth: CGFloat) -> [TimelineSourceElement]
}

/// Delegate objects should implement this protocol

public protocol TimelineCardEventsHandler {
	func didSelectElement(at index: Int, in timelineCard: TimelineCard)
	func didSelectSubElement(at index: (Int, Int), in timelineCard: TimelineCard)
	func didTouchHeaderView(_ headerView: UIView, in timelineCard: TimelineCard)
	func didTouchFooterView(_ footerView: UIView, in timelineCard: TimelineCard)
}

// Optional functions implementation in pure Swift (avoiding Obj-C)

public extension TimelineCardEventsHandler {
	func didTouchHeaderView(_ headerView: UIView, in timelineCard: TimelineCard) { }
	func didTouchFooterView(_ footerView: UIView, in timelineCard: TimelineCard) { }
}

// MARK: Default content options

/// This premade view is used by `TimelineCard` in cases when title and subtitle is enough to describe every element

private class SimpleElementView: UIView {
	// MARK: Constants
	
	static let defaultHeight: CGFloat = 40.0
	
	// MARK: Properties
	
	var titleLabel: UILabel!
	var subtitleLabel: UILabel!
	
	// MARK: Initializers
	
	init(frame: CGRect, title: NSAttributedString, subtitle: NSAttributedString) {
		super.init(frame: frame)
		
		titleLabel = UILabel(frame: CGRect(x: 0, y: 0,
		                                   width: bounds.width, height: bounds.height / 2))
		titleLabel.attributedText = title
		addSubview(titleLabel)
		
		subtitleLabel = UILabel(frame: CGRect(x: 0, y: bounds.height / 2,
		                                   width: bounds.width, height: bounds.height / 2))
		subtitleLabel.attributedText = subtitle
		addSubview(subtitleLabel)
	}
	
	convenience init(width: CGFloat, title: NSAttributedString, subtitle: NSAttributedString) {
		self.init(frame: CGRect.init(x: 0, y: 0, width: width, height: SimpleElementView.defaultHeight), title: title, subtitle: subtitle)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

// MARK: Card

/// Self-drawn and self-layouted Timeline Card view that can be presented anywhere to show group of elements in order. Highly customizable. `TimelineCardDataProvider` and `TimelineCardEventsHandler` protocols must be implemented by user.

public class TimelineCard: UIView {
	// MARK: Types
	
	public enum ItemShape {
		case circle//, square, diamond
	}
	
	/// Structure describing vertical position and span of various elements to be drawn/placed during card reloading process. For example, milestone path/shapes, or milestone description views.
	
	private struct VerticalMetrics {
		struct SpaceBounds {
			var origin: CGFloat = 0
			var height: CGFloat = 0
			var childBounds: [SpaceBounds]? = nil
			
			init(origin: CGFloat, height: CGFloat) {
				self.origin = origin
				self.height = height
			}
		}
		
		var totalHeight: CGFloat = 0
		var elementDescriptionSpaces: [SpaceBounds] = []
		var elementIconSpaces: [SpaceBounds] = []
		
		init() { }
	}
	
	// MARK: Source
	
	// TODO: Should it be limited to class and be weak?
	var dataProvider: TimelineCardDataProvider? = nil
	
	var source: [TimelineSourceElement] = [] {
		didSet {
			if autoreload { reload() }
		}
	}
	
	// MARK: Events delivery
	
	var eventsHandler: TimelineCardEventsHandler? = nil
	
	// MARK: Card appearance
	
	override public var backgroundColor: UIColor? {
		didSet {
			super.backgroundColor = backgroundColor
			setUpAppearance()
		}
	}
	
	var cornerRadius: CGFloat = 20.0 {
		didSet {
			setUpAppearance()
		}
	}
	
	var borderAppearance: (UIColor, CGFloat) = (.lightGray, 1.0) {
		didSet {
			setUpAppearance()
		}
	}
	
	// Temporarily disabled and made private
	private var isMaterial: Bool = true {
		didSet {
			setUpAppearance()
		}
	}
	
	// MARK: Content appearance
	
	var timelineWidth: CGFloat {
		return CGFloat.maximum(itemShapeHeight, CGFloat.maximum(subItemShapeHeight, groupItemShapeHeight))
	}
	
	var descriptionContentWidthLimit: CGFloat {
		return width - (margins.0 +
		timelineWidth + marginAroundTimeline + margins.2)
	}
	
	var timelineViewSize: CGSize {
		return CGSize(width: width, height: bounds.height - (headerView?.bounds.height ?? 0.0) - (footerView?.bounds.height ?? 0.0))
	}
	
	var itemShapeHeight: CGFloat = 40.0 {
		didSet {
			if autoreload { reload() }
		}
	}
	
	var subItemShapeHeight: CGFloat = 30.0 {
		didSet {
			if autoreload { reload() }
		}
	}
	
	var groupItemShapeHeight: CGFloat = 50.0 {
		didSet {
			if autoreload { reload() }
		}
	}
	
	var itemIconScaleFactor: CGFloat = 0.65 {
		didSet {
			if autoreload { reload() }
		}
	}
	
	var lineColor: UIColor = .darkGray {
		didSet {
			if autoreload { reload() }
		}
	}
	
	var timelinePathWidth: CGFloat = 2.0 {
		didSet {
			if autoreload { reload() }
		}
	}
	
	var titleHeight: CGFloat = 30.0 {
		didSet {
			if autoreload { reload() }
		}
	}
	
	var subtitleHeight: CGFloat = 20.0 {
		didSet {
			if autoreload { reload() }
		}
	}
	
	var margins: (CGFloat, CGFloat, CGFloat, CGFloat) = (20.0, 20.0, 20.0, 20.0) {
		didSet {
			if autoreload { reload() }
		}
	}
	
	var headerView: UIView? = nil {
		didSet {
			headerView?.clipsToBounds = true
			if autoreload { reload() }
		}
	}
	
	var footerView: UIView? = nil {
		didSet {
			footerView?.clipsToBounds = true
			if autoreload { reload() }
		}
	}
	
	var paddingBetweenItems: CGFloat = 10.0 {
		didSet {
			if autoreload { reload() }
		}
	}
	
	var paddingBetweenSubItems: CGFloat = 10.0 {
		didSet {
			if autoreload { reload() }
		}
	}
	
	var paddingAroundItemGroup: CGFloat = 40.0 {
		didSet {
			if autoreload { reload() }
		}
	}
	
	private var marginAroundTimeline: CGFloat = 20.0 {
		didSet {
			if autoreload { reload() }
		}
	}
	
	// MARK: Meta

	/// Whether or not card should automatically rebuild itself after one of appearance properties was updated. Default value is true. When false, explicit call of `reload()` method is necessary.
	
	var autoreload: Bool = true {
		didSet {
			if autoreload { reload() }
		}
	}
	
	private var origin: CGPoint = .zero
	private var width: CGFloat = 0.0
	
	private var timelineView = UIView()
	private var timelineContainer = UIView()
	private var descriptionViewsContainer = UIView()
	
	private var timelineMetrics: VerticalMetrics? = nil
	
	// MARK: Initializers
	
	/// Initialized a new card with given fixed width. Height of the created card will be calculated automatically based on its data source, and available after `reloadData()` method execution, explicitly or implicitly when card is added to superview.
	
	/// - Parameters:
	///		- origin: Optional position of the card
	/// 	- width: Static width of the card
	
	required public init(origin: CGPoint = .zero, width: CGFloat) {
		super.init(frame: CGRect(x: origin.x, y: origin.y,
		                         width: width, height: 0))
		
		self.origin = origin
		self.width = width
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: Life cycle
	
	override public func willMove(toSuperview newSuperview: UIView?) {
		super.willMove(toSuperview: newSuperview)
		setUpAppearance()
		reloadData()
	}
	
	func reloadData() {
		guard let provider = dataProvider else { return }
		source = provider.elementsForTimelineCard(self, containerWidth: descriptionContentWidthLimit)
		
		reload()
	}
	
	// MARK: Initial setup
	
	private func setUpAppearance() {
		clipsToBounds = true
		
		roundCorners(radius: cornerRadius)
		applyBorder(color: borderAppearance.0, width: borderAppearance.1)
		
		// The code below won't make difference (see applyShadow() function comment)
		
		if !isMaterial {
			applyShadow(offset: .zero, color: .white, opacity: 0.0, radius: 0.0)
		} else {
			applyShadow(offset: CGSize.init(width: 0.0, height: 1),
			            color: .darkGray, opacity: 0.5, radius: 0)
		}
	}
	
	// MARK: Displaying
	
	private func cleanUp() {
		subviews.forEach { $0.removeFromSuperview() }
		layer.sublayers?.forEach { $0.removeFromSuperlayer() }
		
		timelineMetrics = nil
	}
	
	/// Calculates vertical positions and spans for all the timeline visual elements to be redrawn or placed as subviews.
	/// - Returns: Structure with metrics to be used by builder logic.
	
	private func metricsForCurrentTimeline() -> VerticalMetrics {
		var metrics = VerticalMetrics()
		
		metrics.totalHeight = 0.0
		
		let addHeightOfNextElement: (TimelineSourceElement, Int) -> Void = { element, index in
			if let childElements = element.subelements {
				
				// Get info about description view space
				
				let elementOrigin = metrics.totalHeight
				let elementHeight = element.customView?.bounds.height ?? SimpleElementView.defaultHeight
				
				// Create space info for element's description and icon areas
				
				var elementDescriptionSpaceInfo = TimelineCard.VerticalMetrics.SpaceBounds(origin: elementOrigin, height: elementHeight)
				var elementIconSpaceInfo = TimelineCard.VerticalMetrics.SpaceBounds(origin: metrics.totalHeight, height: self.groupItemShapeHeight)
				
				// Increment total timeline height
				
				let elementSpaceToPadding = CGFloat.maximum(self.groupItemShapeHeight, elementHeight)
				metrics.totalHeight += elementSpaceToPadding
				metrics.totalHeight += self.paddingBetweenSubItems
				
				// Go through children
				
				elementDescriptionSpaceInfo.childBounds = []
				elementIconSpaceInfo.childBounds = []
				
				for subelement in childElements {
					// Get info about description view space
					
					let subelementOrigin = metrics.totalHeight
					let subelementHeight = subelement.customView?.bounds.height ?? SimpleElementView.defaultHeight
					
					// Write subelement space info for element
					
					elementDescriptionSpaceInfo.childBounds?.append(
						TimelineCard.VerticalMetrics.SpaceBounds(origin: subelementOrigin, height: subelementHeight)
					)
					
					let subIconSpaceInfo = TimelineCard.VerticalMetrics.SpaceBounds(origin: subelementOrigin, height: self.subItemShapeHeight)
					elementIconSpaceInfo.childBounds?.append(subIconSpaceInfo)
					
					// Increment total timeline height
					
					let subelementSpaceToPadding = CGFloat.maximum(
						self.subItemShapeHeight, subelementHeight
					)
					metrics.totalHeight += subelementSpaceToPadding
					
					if let lastSub = childElements.last, lastSub.id == subelement.id {
						if index < (self.source.count - 1) {
							metrics.totalHeight += self.paddingAroundItemGroup
						}
					} else {
						metrics.totalHeight += self.paddingBetweenSubItems
					}
				}
				
				metrics.elementDescriptionSpaces.append(elementDescriptionSpaceInfo)
				metrics.elementIconSpaces.append(elementIconSpaceInfo)
			} else {
				// Get info about description view space
				
				let elementOrigin = metrics.totalHeight
				let elementHeight = element.customView?.bounds.height ?? SimpleElementView.defaultHeight
				
				// Increment total timeline height
				
				let elementSpaceToPadding = CGFloat.maximum(self.itemShapeHeight, elementHeight)
				metrics.totalHeight += elementSpaceToPadding
				
				if index < (self.source.count - 1) {
					let outgoingPadding = self.source[index + 1].subelements != nil ? self.paddingAroundItemGroup : self.paddingBetweenItems
					metrics.totalHeight += outgoingPadding
				}
				
				// Write metrics for element's description view and icon space
				
				metrics.elementDescriptionSpaces.append(TimelineCard.VerticalMetrics.SpaceBounds(origin: elementOrigin, height: elementHeight))
				metrics.elementIconSpaces.append(TimelineCard.VerticalMetrics.SpaceBounds(origin: elementOrigin, height: self.itemShapeHeight))
			}
		}
		
		metrics.totalHeight += margins.1 // Top margin
		
		if !source.isEmpty {
			addHeightOfNextElement(source.first!, 0)
			
			for i in 1 ..< source.count {
				addHeightOfNextElement(source[i], i)
			}
		}
		
		metrics.totalHeight += margins.3 // Bottom margin
		
		return metrics
	}
	
	/// Rebuilds timeline from scratch, without reloading data.
	
	func reload() {
		cleanUp()
		
		layoutIfNeeded()
		
		// Calc timeline size
		
		timelineMetrics = metricsForCurrentTimeline()
		
		let totalTimelineHeight = timelineMetrics!.totalHeight
		let itemDescViewsMetrics = timelineMetrics!.elementDescriptionSpaces
		let itemIconsMetrics = timelineMetrics!.elementIconSpaces
		
		// Calc header and footer heights
		
		let headerHeight = headerView?.bounds.height ?? 0.0
		let footerHeight = footerView?.bounds.height ?? 0.0
		
		// Define space and split it into zones
		
		frame = CGRect(x: frame.origin.x, y: frame.origin.y,
		               width: width, height: totalTimelineHeight + headerHeight + footerHeight)
		
		// Create/prepare views
		
		let timelineView = UIView()
		timelineView.clipsToBounds = true
		timelineView.translatesAutoresizingMaskIntoConstraints = false
		
		headerView?.translatesAutoresizingMaskIntoConstraints = false
		footerView?.translatesAutoresizingMaskIntoConstraints = false
		
		// Add subviews
		
		if let header = headerView { addSubview(header) }
		if let footer = footerView { addSubview(footer) }
		addSubview(timelineView)
		
		// Install constraints
		
		if headerView != nil { self.addConstraints(
			[
				NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: headerView!, attribute: .top, multiplier: 1, constant: 0),
				NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: headerView!, attribute: .leading, multiplier: 1, constant: 0),
				NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: headerView!, attribute: .trailing, multiplier: 1, constant: 0),
				NSLayoutConstraint(item: headerView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: headerView?.bounds.height ?? 0)
			]) }
		
		if footerView != nil { self.addConstraints(
			[
				NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: footerView!, attribute: .bottom, multiplier: 1, constant: 0),
				NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: footerView!, attribute: .leading, multiplier: 1, constant: 0),
				NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: footerView!, attribute: .trailing, multiplier: 1, constant: 0),
				NSLayoutConstraint(item: footerView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: footerView?.bounds.height ?? 0)
			]) }
		
		self.addConstraints(
			[
				NSLayoutConstraint(item: headerView ?? self, attribute: headerView != nil ? .bottom : .top, relatedBy: .equal, toItem: timelineView, attribute: .top, multiplier: 1, constant: 0),
				NSLayoutConstraint(item: footerView ?? self, attribute: footerView != nil ? .top : .bottom, relatedBy: .equal, toItem: timelineView, attribute: .bottom, multiplier: 1, constant: 0),
				NSLayoutConstraint(item: timelineView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
				NSLayoutConstraint(item: timelineView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
			])
		
		// Add path for timeline
		
		timelineContainer = UIView(frame: CGRect(x: 0, y: 0, width: margins.0 + timelineWidth + marginAroundTimeline, height: totalTimelineHeight))
		timelineContainer.backgroundColor = .clear
		timelineContainer.clipsToBounds = true
		timelineView.addSubview(timelineContainer)
		
		let timelinePath = pathForCurrentTimeline()
		
		let timelineLayer = CAShapeLayer()
		timelineLayer.frame = timelineContainer.bounds
		timelineLayer.path = timelinePath
		timelineLayer.lineWidth = timelinePathWidth
		timelineLayer.fillColor = UIColor.clear.cgColor
		timelineLayer.strokeColor = lineColor.cgColor
		
		timelineContainer.layer.addSublayer(timelineLayer)
		
		// Add milestone icons
		
		func placeIcon(element: TimelineSourceElement, spaceInfo: TimelineCard.VerticalMetrics.SpaceBounds, isSubelement: Bool) {
			
			guard let icon = element.icon else {
				// TODO: Place default icon?
				return
			}
			
			let groupElement = isSubelement ? false : element.subelements != nil
			let shapeHeightForElement = isSubelement ? subItemShapeHeight : groupElement ? groupItemShapeHeight : self.itemShapeHeight
			
			let imageWidth = shapeHeightForElement * itemIconScaleFactor
			let imageHeight = spaceInfo.height * itemIconScaleFactor
			let imagePaddingX = (shapeHeightForElement - imageWidth) / 2
			let imagePaddingY = (spaceInfo.height - imageHeight) / 2
			
			let imageView = UIImageView(frame: CGRect(x: margins.0 + (timelineWidth / 2 - shapeHeightForElement / 2) + imagePaddingX, y: spaceInfo.origin + imagePaddingY, width: imageWidth, height: imageHeight))
			imageView.image = icon
			imageView.contentMode = .scaleAspectFit
			imageView.backgroundColor = .clear
			
			let maskLayer = CAShapeLayer()
			maskLayer.frame = imageView.bounds
			maskLayer.path = pathForMilestoneShape(element.milestoneShape, at: CGPoint.init(x: imageView.bounds.width / 2, y: imageView.bounds.height / 2), height: spaceInfo.height - timelinePathWidth)
			imageView.layer.mask = maskLayer
			
			timelineContainer.addSubview(imageView)
		}
		
		for i in 0 ..< itemIconsMetrics.count {
			let element = source[i]
			let iconSpaceInfo = itemIconsMetrics[i]
			
			placeIcon(element: element, spaceInfo: iconSpaceInfo, isSubelement: false)
			
			if let subelements = element.subelements,
				let subIconSpaceInfo = iconSpaceInfo.childBounds {
				
				for i in 0 ..< subelements.count {
					placeIcon(element: subelements[i], spaceInfo: subIconSpaceInfo[i],
					          isSubelement: true)
				}
			}
		}
		
		// Add milestone desc views
		
		descriptionViewsContainer = UIView(frame: CGRect(x: margins.0 + timelineWidth + marginAroundTimeline, y: 0, width: descriptionContentWidthLimit, height: timelineViewSize.height))
		descriptionViewsContainer.backgroundColor = .clear
		descriptionViewsContainer.clipsToBounds = true
		timelineView.addSubview(descriptionViewsContainer)
		
		func placeDescriptionView(element: TimelineSourceElement, spaceInfo: TimelineCard.VerticalMetrics.SpaceBounds) {
			
			descViewFlow: if let customView = element.customView {
				customView.clipsToBounds = true
				customView.frame = CGRect(x: 0, y: spaceInfo.origin, width: descriptionViewsContainer.bounds.width, height: spaceInfo.height)
				descriptionViewsContainer.addSubview(customView)
			} else {
				guard let title = element.title, let subtitle = element.subtitle else {
					break descViewFlow
				}
				
				let simpleView = SimpleElementView(width: descriptionViewsContainer.bounds.width,
				                                   title: title, subtitle: subtitle)
				simpleView.frame = CGRect(x: 0, y: spaceInfo.origin, width: descriptionViewsContainer.bounds.width, height: spaceInfo.height)
				descriptionViewsContainer.addSubview(simpleView)
			}
		}
		
		for i in 0 ..< itemDescViewsMetrics.count {
			let element = source[i]
			let descViewSpaceInfo = itemDescViewsMetrics[i]
			
			placeDescriptionView(element: element, spaceInfo: descViewSpaceInfo)
			
			if let subelements = element.subelements,
				let subelementsSpaceInfo = descViewSpaceInfo.childBounds {
				
				for i in 0 ..< subelements.count {
					placeDescriptionView(element: subelements[i], spaceInfo: subelementsSpaceInfo[i])
				}
			}
		}
		
		// Kick view re-draw process
		
		setNeedsDisplay()
	}
	
	// MARK: Drawing
	
	private func pathForMilestoneShape(_ shape: ItemShape,
	                                   at center: CGPoint, height: CGFloat) -> CGPath {
		let path = CGMutablePath()
		
		switch shape {
		case .circle:
			path.addArc(center: center, radius: height / 2, startAngle: -(CGFloat.pi / 2.0), endAngle: 3.0 * CGFloat.pi / 2, clockwise: false)
			
		default:
			break
		}
		
		return path
	}
	
	private func pathForCurrentTimeline() -> CGPath {
		let path = CGMutablePath()
		
		guard !source.isEmpty else { return path }
		
		let timelineCenterX = margins.0 + timelineWidth / 2
		
		let shapeHeightForElementAtIndex: (Int) -> CGFloat = { index in
			return self.source[index].subelements != nil ? self.groupItemShapeHeight : self.itemShapeHeight
		}
		
		let heightOfLineToElementAtIndex: (Int) -> CGFloat = { index in
			guard index > 0 else {
				return 0.0
			}
			
			let paddingToElement = (self.source[index].subelements != nil || self.source[index - 1].subelements != nil) ? self.paddingAroundItemGroup : self.paddingBetweenItems
			let prevDescViewHeight: CGFloat
			let descViewOverMilestoneShapeDelta: CGFloat
			
			if let prevSubelement = self.source[index - 1].subelements?.last {
				prevDescViewHeight = prevSubelement.customView?.bounds.height ?? SimpleElementView.defaultHeight
				descViewOverMilestoneShapeDelta = prevDescViewHeight - self.subItemShapeHeight
			} else {
				prevDescViewHeight = self.source[index - 1].customView?.bounds.height ?? SimpleElementView.defaultHeight
				descViewOverMilestoneShapeDelta = prevDescViewHeight - self.itemShapeHeight
			}
			
			let totalHeightOfLine = (descViewOverMilestoneShapeDelta > 0 ? descViewOverMilestoneShapeDelta : 0) + paddingToElement
			
			return totalHeightOfLine
		}
		
		let heightOfLineToSubElementAtIndexPath:(Int, Int) -> CGFloat = { parentIndex, subIndex in
			let prevSpaceBeforePadding: CGFloat
			
			if subIndex == 0 {
				let prevDescViewHeight = self.source[parentIndex].customView?.bounds.height ?? SimpleElementView.defaultHeight
				
				let descViewOverMilestoneShapeDelta = prevDescViewHeight - self.groupItemShapeHeight
				prevSpaceBeforePadding = descViewOverMilestoneShapeDelta > 0 ? descViewOverMilestoneShapeDelta : 0
			} else {
				let prevDescViewHeight = self.source[parentIndex].subelements?[subIndex - 1].customView?.bounds.height ?? SimpleElementView.defaultHeight
				
				let descViewOverMilestoneShapeDelta = prevDescViewHeight - self.subItemShapeHeight
				prevSpaceBeforePadding = descViewOverMilestoneShapeDelta > 0 ? descViewOverMilestoneShapeDelta : 0
			}
			
			return prevSpaceBeforePadding + self.paddingBetweenSubItems
		}
		
		/// Draw first first-level element
		
		var nextItemShapeOriginY: CGFloat = margins.1
		var nextItemShapeHeight = shapeHeightForElementAtIndex(0)
		var lastItemShapeEndY: CGFloat = 0.0
		
		path.move(to: CGPoint(x: timelineCenterX, y: nextItemShapeOriginY))
		
		let shapePath = pathForMilestoneShape(source[0].milestoneShape, at: CGPoint(x: timelineCenterX, y: nextItemShapeOriginY + nextItemShapeHeight / 2), height: nextItemShapeHeight)
		path.addPath(shapePath)
		
		path.closeSubpath()
		
		if let childElements = source[0].subelements {
			for j in 0 ..< childElements.count {
				lastItemShapeEndY = nextItemShapeOriginY + nextItemShapeHeight
				nextItemShapeOriginY = lastItemShapeEndY + heightOfLineToSubElementAtIndexPath(0, j)
				nextItemShapeHeight = subItemShapeHeight
				
				path.move(to: CGPoint(x: timelineCenterX, y: lastItemShapeEndY))
				path.addLine(to: CGPoint(x: timelineCenterX, y: nextItemShapeOriginY))
				
				let shapePath = pathForMilestoneShape(source[0].subelements?[j].milestoneShape ?? .circle, at: CGPoint(x: timelineCenterX, y: nextItemShapeOriginY + nextItemShapeHeight / 2), height: nextItemShapeHeight)
				path.addPath(shapePath)
				
				path.closeSubpath()
			}
		}
		
		/// Draw remaining first-level elements
		
		for i in 1 ..< source.count {
			lastItemShapeEndY = nextItemShapeOriginY + nextItemShapeHeight
			nextItemShapeOriginY = lastItemShapeEndY + heightOfLineToElementAtIndex(i)
			nextItemShapeHeight = shapeHeightForElementAtIndex(i)
			
			path.move(to: CGPoint(x: timelineCenterX, y: lastItemShapeEndY))
			path.addLine(to: CGPoint(x: timelineCenterX, y: nextItemShapeOriginY))
			
			let shapePath = pathForMilestoneShape(source[i].milestoneShape, at: CGPoint(x: timelineCenterX, y: nextItemShapeOriginY + nextItemShapeHeight / 2), height: nextItemShapeHeight)
			path.addPath(shapePath)
			
			path.closeSubpath()
			
			if let childElements = source[i].subelements {
				for j in 0 ..< childElements.count {
					lastItemShapeEndY = nextItemShapeOriginY + nextItemShapeHeight
					nextItemShapeOriginY = lastItemShapeEndY + heightOfLineToSubElementAtIndexPath(i, j)
					nextItemShapeHeight = subItemShapeHeight
					
					path.move(to: CGPoint(x: timelineCenterX, y: lastItemShapeEndY))
					path.addLine(to: CGPoint(x: timelineCenterX, y: nextItemShapeOriginY))
					
					let shapePath = pathForMilestoneShape(source[i].subelements?[j].milestoneShape ?? .circle, at: CGPoint(x: timelineCenterX, y: nextItemShapeOriginY + nextItemShapeHeight / 2), height: nextItemShapeHeight)
					path.addPath(shapePath)
					
					path.closeSubpath()
				}
			}
		}
		
		/// Ship ready-to-draw path
		
		return path
	}
	
	// MARK: Touch events
	
	override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else {
			super.touchesBegan(touches, with: event)
			return
		}
		
		if let header = headerView, header.frame.contains(touch.location(in: self)) {
			eventsHandler?.didTouchHeaderView(header, in: self)
		} else if let footer = footerView, footer.frame.contains(touch.location(in: self)) {
			eventsHandler?.didTouchFooterView(footer, in: self)
		} else if let touchedIndex = elementIndexAtTimelineLocation(touch.location(in: timelineView)) {
			if let subIndex = touchedIndex.1 {
				eventsHandler?.didSelectSubElement(at: (touchedIndex.0, subIndex), in: self)
			} else {
				eventsHandler?.didSelectElement(at: touchedIndex.0, in: self)
			}
			
		}
		
		super.touchesBegan(touches, with: event)
	}
	
	private func elementIndexAtTimelineLocation(_ location: CGPoint) -> (Int, Int?)? {
		guard let metrics = timelineMetrics else { return nil }
		
		func indexOfLocation(_ location: CGPoint, in spaces: [VerticalMetrics.SpaceBounds], containerOriginX: CGFloat, containerWidth: CGFloat) -> (Int, Int?)? {
			for i in 0 ..< spaces.count {
				let spaceInfo = spaces[i]
				let spaceFrame = CGRect(x: containerOriginX, y: spaceInfo.origin, width: containerWidth,
										height: spaceInfo.height)
				if spaceFrame.contains(location) {
					return (i, nil)
				} else if let subspacesInfo = spaceInfo.childBounds {
					for j in 0 ..< subspacesInfo.count {
						let subSpaceInfo = subspacesInfo[j]
						let subSpaceFrame = CGRect(x: containerOriginX, y: subSpaceInfo.origin, width: containerWidth, height: subSpaceInfo.height)
						
						if subSpaceFrame.contains(location) {
							return (i, j)
						}
					}
				}
			}
			
			return nil
		}
		
		return indexOfLocation(timelineView.convert(location, to: timelineContainer), in: metrics.elementIconSpaces, containerOriginX: margins.0, containerWidth: timelineContainer.bounds.width) ?? indexOfLocation(timelineView.convert(location, to: descriptionViewsContainer), in: metrics.elementDescriptionSpaces, containerOriginX: 0, containerWidth: descriptionViewsContainer.bounds.width)
	}
}

// MARK: Helper extension

fileprivate extension TimelineCard {
	func roundCorners(radius: CGFloat) {
		layer.cornerRadius = radius
	}
	
	func applyBorder(color: UIColor, width: CGFloat) {
		layer.borderColor = color.cgColor
		layer.borderWidth = width
	}
	
	func applyShadow(offset: CGSize, color: UIColor, opacity: Float, radius: CGFloat) {
		// This is turned off until someone (me?) fixes shadow for round bordered views. It's low priority for me at the moment.
		return;
		
		layer.masksToBounds = false
		layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
		layer.shadowColor = color.cgColor
		layer.shadowOffset = offset
		layer.shadowOpacity = opacity
		layer.shadowRadius = radius
	}
}

//
//  TimelineItem.swift
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

import Foundation
import UIKit

/// Main building block of input data for `TimelineCard` or `TimelineFeed` views. It implements `TimelineSourceElement` protocol that describes all the necessary properties `TimelineCard` needs in order to automatically draw and lay out itself.

public class TimelineItem: TimelineSourceElement {
	public let id: UUID
	
	public var subelements: [TimelineSourceElement]? = nil
	
	public var milestoneShape: TimelineCard.ItemShape
	public var title: NSAttributedString?
	public var subtitle: NSAttributedString?
	public var customView: UIView?
	public var icon: UIImage?
	
	public init(title: NSAttributedString, subtitle: NSAttributedString,
	     shape: TimelineCard.ItemShape = .circle, icon: UIImage? = nil) {
		
		id = UUID()
		
		self.title = title
		self.subtitle = subtitle
		self.milestoneShape = shape
		self.icon = icon
	}
	
	public init(customView: UIView, shape: TimelineCard.ItemShape = .circle, icon: UIImage? = nil) {
		id = UUID()
		
		self.milestoneShape = shape
		self.icon = icon
		self.customView = customView
	}
}

/// Extended version of `TimelineItem` that supports children.

public class TimelineItemGroup: TimelineItem {
	public init(title: NSAttributedString, subtitle: NSAttributedString, items: [TimelineItem],
		 shape: TimelineCard.ItemShape = .circle, icon: UIImage? = nil) {
		
		super.init(title: title, subtitle: subtitle, shape: shape, icon: icon)
		
		self.subelements = items
	}
	
	public init(customView: UIView, items: [TimelineItem], shape: TimelineCard.ItemShape = .circle, icon: UIImage? = nil) {
		
		super.init(customView: customView, shape: shape, icon: icon)
		
		self.subelements = items
	}
}

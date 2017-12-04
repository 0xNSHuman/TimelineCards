//
//  TestModel.swift
//  TimelineCardDemo
//
//  Created by Vladislav Averin on 30/11/2017.
//

import Foundation
import UIKit

// MARK: Model

class TimelineDataCollection {
	let items: [TimelineData]
	
	init() {
		var items = [TimelineData]()
		for i in 0 ..< ((arc4random() % 400) + 200) {
			items.append(TimelineData(date: NSCalendar.current.startOfDay(for: NSDate(timeIntervalSinceNow: TimeInterval(60 * 60 * 24 * i)) as Date) as NSDate))
		}
		
		self.items = items
	}
}

class TimelineData {
	let date: NSDate
	let events: [TimelineEvent]
	
	init(date: NSDate) {
		self.date = date
		
		var events = [TimelineEvent]()
		for _ in 0 ..< ((arc4random() % 9) + 1) {
			events.append(TimelineEvent(date: date))
		}
		
		self.events = events
	}
}

class TimelineEvent {
	let icon = randomImage()
	let eventName: String
	let eventDescription: String
	let eventTime: NSDate
	let assignee = "John Doe"
	
	let subevents: [TimelineEvent]?
	
	init(date: NSDate, isFirstLevel: Bool = true) {
		eventTime = date.addingTimeInterval(TimeInterval(arc4random() % (60 * 60 * 24)))
		eventName = randomString(length: 10)
		eventDescription = randomString(length: 40)
		
		// Make it a group with 2/10 chance
		guard isFirstLevel, arc4random() % 10 < 2 else {
			self.subevents = nil
			return
		}
		
		var subevents = [TimelineEvent]()
		for _ in 0 ..< ((arc4random() % 3) + 2) {
			subevents.append(TimelineEvent(date: eventTime, isFirstLevel: false))
		}
		
		self.subevents = subevents
	}
}

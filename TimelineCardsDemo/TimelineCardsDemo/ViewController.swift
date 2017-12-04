//
//  ViewController.swift
//  TimelineCardDemo
//
//  Created by Vladislav Averin on 27/11/2017.
//

import UIKit
import TimelineCards

class ViewController: UIViewController, TimelineFeedDataSource, TimelineFeedDelegate {
	// MARK: Properties
	
	var timelineFeed = TimelineFeed()
	let testCollection = TimelineDataCollection()
	
	// MARK: Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let bgView = UIImageView(frame: view.bounds)
		bgView.image = UIImage(named: "bg.jpg")
		bgView.contentMode = .scaleAspectFill
		view.addSubview(bgView)
		
		let darkeningLayer = CALayer()
		darkeningLayer.frame = bgView.bounds
		darkeningLayer.backgroundColor = UIColor.init(white: 0.0, alpha: 0.3).cgColor
		bgView.layer.addSublayer(darkeningLayer)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		setUpFeed()
	}
	
	// MARK: Test setup
	
	private func setUpFeed() {
		guard timelineFeed.superview == nil else { return }
		
		timelineFeed.frame = CGRect(x: 0, y: 0, width: view.bounds.width * 0.8, height: view.bounds.height)
		
		timelineFeed.center = view.center
		timelineFeed.dataSource = self
		timelineFeed.delegate = self
		
		timelineFeed.topMargin = 30.0
		timelineFeed.bottomMargin = 10.0
		
		timelineFeed.alpha = 0.0
		view.addSubview(timelineFeed)
		timelineFeed.reloadData()
		
		animate(block: {
			self.timelineFeed.alpha = 1.0
		})
	}
	
	// MARK: TimelineFeedDataSource
	
	func numberOfCards(in timelineFeed: TimelineFeed) -> Int {
		return testCollection.items.count
	}
	
	func card(at index: Int, in timelineFeed: TimelineFeed) -> TimelineCard {
		let timelineCard = TimelineCard(origin: .zero, width: timelineFeed.bounds.width)
		timelineCard.backgroundColor = .white
		
		if [2,4,7].contains(index % 10) {
			let header = UIView(frame: CGRect(x: 0, y: 0,
											  width: timelineCard.bounds.width,
											  height: 60))
			header.backgroundColor = randomPastelColor()
			
			let headerLabel = UILabel(frame: CGRect(x: 0, y: 0,
													width: header.bounds.width, height: header.bounds.height))
			headerLabel.text = "Custom UIView Header #\(index)"
			headerLabel.textColor = .white
			headerLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 24.0)
			headerLabel.textAlignment = .center
			header.addSubview(headerLabel)
			
			timelineCard.headerView = header
		}
		
		if [3,4,8].contains(index % 10) {
			let footer = UIView(frame: CGRect(x: 0, y: 0,
											  width: timelineCard.bounds.width,
											  height: 100))
			footer.backgroundColor = randomPastelColor()
			
			let footerLabel = UILabel(frame: CGRect(x: 0, y: 0,
													width: footer.bounds.width, height: footer.bounds.height))
			footerLabel.text = "Custom UIView Footer #\(index)"
			footerLabel.textColor = .white
			footerLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 24.0)
			footerLabel.textAlignment = .center
			footer.addSubview(footerLabel)
			
			timelineCard.footerView = footer
		}
		
		return timelineCard
	}
	
	func elementsForTimelineCard(at index: Int, containerWidth: CGFloat) -> [TimelineSourceElement] {
		var elements = [] as [TimelineSourceElement]
		
		let timelineData = testCollection.items[index]
		
		for event in timelineData.events {
			if event.subevents == nil {
				let itemDescView = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: 60))
				itemDescView.backgroundColor = .clear
				
				let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: itemDescView.bounds.width * 0.7, height: itemDescView.bounds.height * 0.4))
				titleLabel.text = event.eventName
				titleLabel.textColor = .black
				titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 22.0)
				itemDescView.addSubview(titleLabel)
				
				let subtitleLabel = UILabel(frame: CGRect(x: 0, y: itemDescView.bounds.height * 0.4, width: itemDescView.bounds.width * 0.7, height: itemDescView.bounds.height * 0.6))
				subtitleLabel.textColor = .darkGray
				subtitleLabel.numberOfLines = 2
				subtitleLabel.font = UIFont(name: "HelveticaNeue-Light", size: 12.0)
				subtitleLabel.text = event.eventDescription
				itemDescView.addSubview(subtitleLabel)
				
				let toolBarIcon1 = UIImageView(frame: CGRect(x: titleLabel.bounds.width + itemDescView.bounds.width * 0.1, y: 0, width: (itemDescView.bounds.width - titleLabel.bounds.width) - itemDescView.bounds.width * 0.1, height: itemDescView.bounds.height))
				toolBarIcon1.image = UIImage(named: "checkmark")?.applying(tintColor: .purple)
				toolBarIcon1.contentMode = .scaleAspectFit
				itemDescView.addSubview(toolBarIcon1)
				
				elements.append(TimelineItem.init(customView: itemDescView,
												  icon: event.icon.applying(tintColor: randomPastelColor())))
			} else {
				let groupDescView = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: 50))
				groupDescView.backgroundColor = .clear
				
				let titleLabel = UILabel(frame: CGRect(x: 0, y: 0,
													   width: groupDescView.bounds.width, height: groupDescView.bounds.height))
				
				let titleAttributedStr = NSAttributedString(string: "GROUP OF EVENTS (\(event.subevents?.count ?? 0))", attributes: [
					.foregroundColor : UIColor.orange,
					NSAttributedStringKey.font : UIFont(name: "HelveticaNeue-Bold", size: 20.0) ?? UIFont(),
					.strokeWidth : 3
					])
				
				titleLabel.attributedText = titleAttributedStr
				groupDescView.addSubview(titleLabel)
				
				func subItemDescView(for subEvent: TimelineEvent) -> UIView {
					let subItemDescView = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: 50))
					subItemDescView.backgroundColor = .clear
					
					let titleLabel = UILabel(frame: CGRect(x: 0, y: 0,
														   width: subItemDescView.bounds.width * 0.7, height: subItemDescView.bounds.height * 0.7))
					titleLabel.text = subEvent.eventName
					titleLabel.textColor = .black
					titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 22.0)
					subItemDescView.addSubview(titleLabel)
					
					let subtitleLabel = UILabel(frame: CGRect(x: 0, y: subItemDescView.bounds.height * 0.7,
															  width: subItemDescView.bounds.width * 0.7, height: subItemDescView.bounds.height * 0.3))
					subtitleLabel.textColor = .purple
					subtitleLabel.font = UIFont(name: "HelveticaNeue-Regular", size: 18.0)
					subtitleLabel.text = "\(stringFromDate(subEvent.eventTime as Date, format: "HH:mm") ?? "00:00"); \(subEvent.assignee)"
					subItemDescView.addSubview(subtitleLabel)
					
					let toolBarIcon1 = UIImageView(frame: CGRect(x: titleLabel.bounds.width + subItemDescView.bounds.width * 0.1, y: 0, width: (subItemDescView.bounds.width - titleLabel.bounds.width) - subItemDescView.bounds.width * 0.1, height: subItemDescView.bounds.height))
					toolBarIcon1.image = UIImage(named: "proceed")?.applying(tintColor: .orange)
					toolBarIcon1.contentMode = .scaleAspectFit
					subItemDescView.addSubview(toolBarIcon1)
					
					return subItemDescView
				}
				
				var subItems = [TimelineItem]()
				for subEvent in event.subevents! {
					subItems.append(TimelineItem.init(customView: subItemDescView(for: subEvent),
													  icon: subEvent.icon.applying(tintColor: randomPastelColor())))
				}
				
				elements.append(TimelineItemGroup(customView: groupDescView,
												  items: subItems, icon: UIImage(named: "three_dots")!.applying(tintColor: .darkGray)))
			}
		}
		
		return elements
	}
	
	func headerViewForCard(at index: Int, in timelineFeed: TimelineFeed) -> UIView? {
		let customHeader = UIView(frame: CGRect(x: 0, y: 0, width: timelineFeed.bounds.width, height: 60.0))
		customHeader.backgroundColor = .purple
		
		return nil//customHeader
	}
	
	func titleAndSubtitle(at index: Int, in timelineFeed: TimelineFeed) -> (NSAttributedString, NSAttributedString?)? {
		
		let timelineData = testCollection.items[index]
		
		let testTitle = NSAttributedString(string: stringFromDate(timelineData.date as Date, format: "MMMM, dd") ?? "", attributes: [
			.foregroundColor : UIColor.white,
			NSAttributedStringKey.font : UIFont(name: "HelveticaNeue-Bold", size: 23.0) ?? UIFont(),
			])
		let testSubtitle = NSAttributedString(string: "Sample Timeline Card #\(index)", attributes: [
			.foregroundColor : UIColor.white,
			NSAttributedStringKey.font : UIFont(name: "HelveticaNeue-Bold", size: 20.0) ?? UIFont(),
			])
		
		return (testTitle, testSubtitle)
	}
	
	// MARK: TimelineFeedDelegate
	
	func didSelectElement(at index: Int, timelineCardIndex: Int) {
		print("Did select item #\(index) at card #\(timelineCardIndex)")
		
		let timelineData = testCollection.items[timelineCardIndex]
		let event = timelineData.events[index]
		showDetailsForEvent(event)
	}
	
	func didSelectSubElement(at index: (Int, Int), timelineCardIndex: Int) {
		print("Did select subitem #\(index.0);\(index.1) at card #\(timelineCardIndex)")
		
		let timelineData = testCollection.items[timelineCardIndex]
		if let event = timelineData.events[index.0].subevents?[index.1] {
			showDetailsForEvent(event)
		}
	}
	
	func didTouchHeaderView(_ headerView: UIView, timelineCardIndex: Int) {
		print("Did touch header (\(headerView)) at card #\(timelineCardIndex)")
		present(alert(title: "Touch event", text: "Did touch header (\(headerView)) at card #\(timelineCardIndex)"), animated: true, completion: nil)
	}
	
	func didTouchFooterView(_ footerView: UIView, timelineCardIndex: Int) {
		print("Did touch footer (\(footerView)) at card #\(timelineCardIndex)")
		present(alert(title: "Touch event", text: "Did touch footer (\(footerView)) at card #\(timelineCardIndex)"), animated: true, completion: nil)
	}
	
	// MARK: Transitions
	
	private func showDetailsForEvent(_ event: TimelineEvent) {
		let detailsVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: String.init(describing: DetailsViewController.self)) as! DetailsViewController
		detailsVC.events = event.subevents ?? [event]
		navigationController?.pushViewController(detailsVC, animated: true)
	}
}

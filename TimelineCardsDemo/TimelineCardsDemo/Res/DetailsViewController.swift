//
//  DetailsViewController.swift
//  TimelineCardDemo
//
//  Created by Vladislav Averin on 01/12/2017.
//  Copyright © 2017 Vlad Averin. All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController, TimelineCardDataProvider, TimelineCardEventsHandler {
	// MARK: Outlets
	
	@IBOutlet weak var container: UIView!
	
	// MARK: Properties
	
	var events: [TimelineEvent] = []
	var demoTimer = Timer()
	
	// MARK: Initializers
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	// MARK: View life cycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		let bgView = UIImageView(frame: view.bounds)
		bgView.image = UIImage(named: "bg.jpg")
		bgView.contentMode = .scaleAspectFill
		view.insertSubview(bgView, at: 0)
		
		let darkeningLayer = CALayer()
		darkeningLayer.frame = bgView.bounds
		darkeningLayer.backgroundColor = UIColor.init(white: 0.0, alpha: 0.3).cgColor
		bgView.layer.addSublayer(darkeningLayer)
		
		let swipeBack = UISwipeGestureRecognizer(target: self, action: #selector(swipedBack))
		swipeBack.direction = .right
		view.addGestureRecognizer(swipeBack)
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		presentCard()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		demoTimer.invalidate()
	}
	
	// MARK: Card presentation
	
	private func presentCard() {
		func card(width: CGFloat) -> TimelineCard {
			let detailsCard = TimelineCard(width: width)
			detailsCard.dataProvider = self
			detailsCard.eventsHandler = self
			
			return detailsCard
		}
		
		if events.count == 1 {
			let demoInstancesCount = 5
			let padding: CGFloat = 20.0
			let cardWidth: CGFloat = container.bounds.width * 0.8
			let sidePadding: CGFloat = container.bounds.width * 0.2
			
			let cardsContainer = UIView()
			cardsContainer.backgroundColor = .clear
			
			var accumulatedHeight: CGFloat = 0
			var demoCards = [TimelineCard]()
			for i in 0 ..< demoInstancesCount {
				let demoCard = card(width: cardWidth)
				
				demoCard.backgroundColor = UIColor.white
				demoCard.reloadData()
				
				demoCard.frame = CGRect(x: i % 2 > 0 ? 0 : sidePadding, y: accumulatedHeight, width: cardWidth, height: demoCard.bounds.height)
				
				demoCard.borderAppearance = (randomPastelColor(), CGFloat(i % 3 + 1))
				demoCard.cornerRadius = CGFloat(arc4random() % 25)
				demoCard.lineColor = randomPastelColor()
				demoCard.itemShapeHeight = CGFloat(arc4random() % 30 + 25)
				demoCard.timelinePathWidth = CGFloat(arc4random() % 3 + 1)
				demoCard.margins = (CGFloat(arc4random() % 20 + 10), CGFloat(arc4random() % 20 + 10), CGFloat(arc4random() % 20 + 10), CGFloat(arc4random() % 20 + 10))
				
				accumulatedHeight += padding + demoCard.bounds.height
				demoCards.append(demoCard)
				cardsContainer.addSubview(demoCard)
			}
			
			cardsContainer.frame = CGRect(x: 0, y: 0, width: container.bounds.width, height: padding * CGFloat(demoInstancesCount - 1) + demoCards.reduce(CGFloat(0.0), { $0 + $1.bounds.height }))
			
			cardsContainer.center = CGPoint(x: container.bounds.width /  2,
											y: container.bounds.height /  2)
			cardsContainer.alpha = 0.0
			container.addSubview(cardsContainer)
			
			UIView.animate(withDuration: 0.25, animations: {
				cardsContainer.alpha = 1.0
			}, completion: nil)
		} else {
			let detailsCard = card(width: container.bounds.width)
			detailsCard.backgroundColor = .white
			
			let header = UIView(frame: CGRect(x: 0, y: 0,
											  width: detailsCard.bounds.width,
											  height: 60))
			header.backgroundColor = randomPastelColor()
			detailsCard.headerView = header
			
			let bgViewHeader = UIImageView(frame: header.bounds)
			bgViewHeader.image = UIImage(named: "sample_bg_0.jpg")
			bgViewHeader.contentMode = .scaleAspectFill
			header.insertSubview(bgViewHeader, at: 0)
			
			let headerLabel = UILabel(frame: CGRect(x: 0, y: 0,
													width: header.bounds.width, height: header.bounds.height))
			headerLabel.text = "Custom UIView Header"
			headerLabel.textColor = .white
			headerLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 22.0)
			headerLabel.textAlignment = .center
			header.addSubview(headerLabel)
			
			let separatorViewH = UIView(frame: CGRect(x: 0, y: header.bounds.height - 2, width: header.bounds.width, height: 2))
			separatorViewH.backgroundColor = .lightGray
			header.addSubview(separatorViewH)
			
			let footer = UIView(frame: CGRect(x: 0, y: 0,
											  width: detailsCard.bounds.width,
											  height: 100))
			footer.backgroundColor = randomPastelColor()
			detailsCard.footerView = footer
			
			let footerLabel = UILabel(frame: CGRect(x: 0, y: 0,
													width: footer.bounds.width, height: footer.bounds.height))
			footerLabel.text = "Custom UIView Footer"
			footerLabel.textColor = .white
			footerLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 22.0)
			footerLabel.textAlignment = .center
			footer.addSubview(footerLabel)
			
			let bgViewFooter = UIImageView(frame: footer.bounds)
			bgViewFooter.image = UIImage(named: "sample_bg_1.jpg")
			bgViewFooter.contentMode = .scaleAspectFill
			footer.insertSubview(bgViewFooter, at: 0)
			
			let separatorViewF = UIView(frame: CGRect(x: 0, y: 0, width: footer.bounds.width, height: 2))
			separatorViewF.backgroundColor = .lightGray
			footer.addSubview(separatorViewF)
			
			container.addSubview(detailsCard)
			detailsCard.center = CGPoint(x: container.bounds.width /  2,
										 y: container.bounds.height /  2)
			
			demoTimer = Timer(timeInterval: 1.0, repeats: true, block: { (timer) in
				detailsCard.backgroundColor = Int(Date().timeIntervalSince1970) % 5 != 0 ? randomPastelColor() : .clear
				detailsCard.borderAppearance = (randomPastelColor(), CGFloat(arc4random() % 7))
				detailsCard.cornerRadius = CGFloat(arc4random() % 25)
				detailsCard.lineColor = randomPastelColor()
				detailsCard.itemShapeHeight = CGFloat(arc4random() % 30 + 20)
				detailsCard.timelinePathWidth = CGFloat(arc4random() % 5 + 1)
				detailsCard.margins = (CGFloat(arc4random() % 20 + 10), CGFloat(arc4random() % 20 + 10), CGFloat(arc4random() % 20 + 10), CGFloat(arc4random() % 20 + 10))
				
				detailsCard.reloadData()
				
				detailsCard.center = CGPoint(x: self.container.bounds.width /  2,
											 y: self.container.bounds.height /  2)
			})
			
			RunLoop.main.add(demoTimer, forMode: .defaultRunLoopMode)
		}
	}

	// MARK: TimelineCardDataProvider
	
	func elementsForTimelineCard(_ timelineCard: TimelineCard,
								 containerWidth: CGFloat) -> [TimelineSourceElement] {
		
		var cardSource = [] as [TimelineSourceElement]
		
		for event in events {
			if event.subevents == nil {
				if events.count == 1 {
					let itemDescView = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: 60))
					itemDescView.backgroundColor = .clear
					
					let titleLabel = UILabel(frame: CGRect(x: 0, y: 0,
														   width: itemDescView.bounds.width * 0.7, height: itemDescView.bounds.height * 0.4))
					titleLabel.text = event.eventName
					titleLabel.textColor = randomPastelColor()
					titleLabel.font = UIFont(name: ["HelveticaNeue-Light", "CourierNew-Regular", "TimesNewRoman-Regular"][Int(arc4random() % 3)], size: 22.0)
					itemDescView.addSubview(titleLabel)
					
					switch(arc4random() % 4) {
					case 0:
						let timerView = ORBVisualTimerBar.init(barAnimationStyle: .ORBVisualTimerBarAnimationStyleStraight, frame: CGRect(x: 0, y: itemDescView.bounds.height * 0.4, width: itemDescView.bounds.width * 0.7, height: itemDescView.bounds.height * 0.6), timeRemaining: 5.0)
						
						timerView?.showTimerLabel = false
						timerView?.backgroundViewColor = .clear
						timerView?.timerShapeActiveColor = randomPastelColor()
						timerView?.timerShapeInactiveColor = .lightGray
						timerView?.barCapStyle = "kCALineCapSquare"
						timerView?.barThickness = itemDescView.bounds.height * 0.5
						
						itemDescView.addSubview(timerView ?? UIView())
						
						timerView?.start()
						
						let toolBarIcon1 = UIImageView(frame: CGRect(x: titleLabel.bounds.width + itemDescView.bounds.width * 0.1, y: 0, width: (itemDescView.bounds.width - titleLabel.bounds.width) - itemDescView.bounds.width * 0.1, height: itemDescView.bounds.height))
						toolBarIcon1.image = UIImage(named: "checkmark")?.applying(tintColor: .purple)
						toolBarIcon1.contentMode = .scaleAspectFit
						itemDescView.addSubview(toolBarIcon1)
						
					case 1:
						let subtitleLabel = UILabel(frame: CGRect(x: 0, y: itemDescView.bounds.height * 0.4, width: itemDescView.bounds.width, height: itemDescView.bounds.height * 0.6))
						subtitleLabel.textColor = randomPastelColor()
						subtitleLabel.numberOfLines = 2
						subtitleLabel.font = UIFont(name: ["HelveticaNeue-Light", "CourierNew-Regular", "TimesNewRoman-Bold"][Int(arc4random() % 3)], size: 12.0)
						subtitleLabel.text = event.eventDescription
						itemDescView.addSubview(subtitleLabel)
						
					case 2:
						let bgView = UIImageView(frame: CGRect(x: 0, y: itemDescView.bounds.height * 0.4, width: itemDescView.bounds.width, height: itemDescView.bounds.height * 0.6))
						bgView.image = UIImage(named: "sample_bg_1.jpg")
						bgView.contentMode = .scaleAspectFill
						bgView.layer.cornerRadius = 20.0
						itemDescView.insertSubview(bgView, at: 0)
						
					default:
						titleLabel.frame = CGRect(x: 0, y: itemDescView.bounds.height * 0.5, width: itemDescView.bounds.width, height: itemDescView.bounds.height * 0.5)
						
						let trashContainer = UIView(frame: CGRect(x: 0, y: 0, width: itemDescView.bounds.width, height: itemDescView.bounds.height * 0.5))
						trashContainer.backgroundColor = .clear
						
						for i in 0 ..< 2 {
							let subview: UIView
							let frame = CGRect(x: (trashContainer.bounds.width / 2) * CGFloat(i), y: 0, width: trashContainer.bounds.width / 2 * 0.8, height: trashContainer.bounds.height)
							
							switch(i) {
							case 0:
								let view = UISegmentedControl(items: ["0", "1", "2"])
								view.frame = frame
								subview = view
							default:
								let view = UISwitch(frame: frame)
								subview = view
							}
							
							trashContainer.addSubview(subview)
						}
						
						itemDescView.insertSubview(trashContainer, at: 0)
					}
					
					cardSource.append(TimelineItem.init(customView: itemDescView,
														icon: event.icon.applying(tintColor: randomPastelColor())))
				} else {
					let itemDescView = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: CGFloat(arc4random() % 20 + 40)))
					itemDescView.backgroundColor = randomPastelColor()
					
					let titleLabel = UILabel(frame: CGRect(x: 0, y: 0,
														   width: itemDescView.bounds.width, height: itemDescView.bounds.height / 3 * 2))
					titleLabel.text = "Custom UIView"
					titleLabel.textColor = .white
					titleLabel.textAlignment = .center
					titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 22.0)
					itemDescView.addSubview(titleLabel)
					
					let subtitleLabel = UILabel(frame: CGRect(x: 0, y: itemDescView.bounds.height / 3 * 2,
															  width: itemDescView.bounds.width, height: itemDescView.bounds.height / 3))
					subtitleLabel.textColor = .white
					subtitleLabel.textAlignment = .center
					subtitleLabel.numberOfLines = 1
					subtitleLabel.font = UIFont(name: "HelveticaNeue-Light", size: 14.0)
					subtitleLabel.text = "Or standard Title/Subtitle preset"
					itemDescView.addSubview(subtitleLabel)
					
					cardSource.append(TimelineItem.init(customView: itemDescView,
														icon: event.icon.applying(tintColor: randomPastelColor())))
				}
			}
		}
		
		return cardSource
	}
	
	// MARK: TimelineCardEventsHendler
	
	func didSelectElement(at index: Int, in timelineCard: TimelineCard) {
		print("Did select item #\(index) in card \(timelineCard)")
		present(alert(title: "Touch event", text: "Did select item #\(index) in card \(timelineCard)"), animated: true, completion: nil)
	}
	
	func didSelectSubElement(at index: (Int, Int), in timelineCard: TimelineCard) {
		print("Did select subitem #\(index.0);\(index.1) in card \(timelineCard)")
		present(alert(title: "Touch event", text: "Did select subitem #\(index.0);\(index.1) in card \(timelineCard)"), animated: true, completion: nil)
	}
	
	func didTouchHeaderView(_ headerView: UIView, in timelineCard: TimelineCard) {
		print("Did touch header (\(headerView)) in card \(timelineCard)")
		present(alert(title: "Touch event", text: "Did touch header (\(headerView)) in card \(timelineCard)"), animated: true, completion: nil)
	}
	
	func didTouchFooterView(_ footerView: UIView, in timelineCard: TimelineCard) {
		print("Did touch footer (\(footerView)) in card \(timelineCard)")
		present(alert(title: "Touch event", text: "Did touch footer (\(footerView)) in card \(timelineCard)"), animated: true, completion: nil)
	}
	
	// MARK: Touch events
	
	@objc private func swipedBack() {
		_ = navigationController?.popViewController(animated: true)
	}
}

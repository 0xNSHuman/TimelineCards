//
//  TimelineFeed.swift
//  Created by Vladislav Averin on 10/11/2017.

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

/// Protocol that `TimelineFeed` uses to create `TimelineCard`s, populate them with data, and then reuse when needed. Must be implemented by data source in order to present feed of cards.

public protocol TimelineFeedDataSource {
	func numberOfCards(in timelineFeed: TimelineFeed) -> Int
	func card(at index: Int, in timelineFeed: TimelineFeed) -> TimelineCard
	func elementsForTimelineCard(at index: Int, containerWidth: CGFloat) -> [TimelineSourceElement]
	
	func titleAndSubtitle(at index: Int,
	                      in timelineFeed: TimelineFeed) -> (NSAttributedString, NSAttributedString?)?
	func headerViewForCard(at index: Int, in timelineFeed: TimelineFeed) -> UIView?
}

// Optional protocol methods implementation for pure Swift

public extension TimelineFeedDataSource {
	func titleAndSubtitle(at index: Int,
	                      in timelineFeed: TimelineFeed) -> (NSAttributedString, NSAttributedString?)? {
		return nil
	}
	
	func headerViewForCard(at index: Int, in timelineFeed: TimelineFeed) -> UIView? {
		return nil
	}
}

/// Protocol that `TimelineFeed` uses to deliver events from cards. Must be implemented by delegate in order to handle interaction, such as touch events coming from users.

public protocol TimelineFeedDelegate {
	func didSelectElement(at index: Int, timelineCardIndex: Int)
	func didSelectSubElement(at index: (Int, Int), timelineCardIndex: Int)
	func didTouchHeaderView(_ headerView: UIView, timelineCardIndex: Int)
	func didTouchFooterView(_ footerView: UIView, timelineCardIndex: Int)
}

// Optional protocol methods implementation for pure Swift

public extension TimelineFeedDelegate {
	func didTouchHeaderView(_ headerView: UIView, timelineCardIndex: Int) { }
	func didTouchFooterView(_ footerView: UIView, timelineCardIndex: Int) { }
}

/// Simple view that's used by `TimelineFeed` by default in cases when titile and subtitle are enough to describe a single card in feed.

fileprivate class SimpleTimelineItemHeader: UIView {
	// MARK: Constants
	
	static let defaultHeight: CGFloat = 60.0
	static let defaultPadding: CGFloat = 10.0
	
	// MARK: Properties
	
	var titleLabel: UILabel!
	var subtitleLabel: UILabel!
	
	// MARK: Initializers
	
	init(frame: CGRect, title: NSAttributedString, subtitle: NSAttributedString? = nil) {
		super.init(frame: frame)
		
		backgroundColor = .clear
		self.translatesAutoresizingMaskIntoConstraints = false
		
		let titlesContainer = UIView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - SimpleTimelineItemHeader.defaultPadding))
		titlesContainer.backgroundColor = .clear
		addSubview(titlesContainer)
		
		let titleHeight: CGFloat = subtitle != nil ? titlesContainer.bounds.height / 2 : titlesContainer.bounds.height
		
		titleLabel = UILabel(frame: CGRect(x: 0, y: 0,
		                                   width: titlesContainer.bounds.width, height: titleHeight))
		titleLabel.attributedText = title
		titlesContainer.addSubview(titleLabel)
		
		if let subtitle = subtitle {
			subtitleLabel = UILabel(frame: CGRect(x: 0, y: titlesContainer.bounds.height / 2,
			                                      width: titlesContainer.bounds.width, height: titlesContainer.bounds.height / 2))
			subtitleLabel.attributedText = subtitle
			titlesContainer.addSubview(subtitleLabel)
		}
	}
	
	convenience init(width: CGFloat, title: NSAttributedString, subtitle: NSAttributedString) {
		self.init(frame: CGRect.init(x: 0, y: 0, width: width, height: SimpleTimelineItemHeader.defaultHeight + SimpleTimelineItemHeader.defaultPadding), title: title, subtitle: subtitle)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

/// Part of internal structure handling feed presentation and reusability.

fileprivate class TimelineFeedCell: UITableViewCell {
	// MARK: Subviews
	
	private(set) var headerView: UIView? = nil
	var card: TimelineCard? = nil
	
	// MARK: Meta
	
	var bottomPadding: CGFloat = 0.0 {
		didSet {
			guard card != nil else { return }
			
			constraints.forEach {
				if $0.secondItem is TimelineCard, $0.secondAttribute == .bottom {
					$0.constant = bottomPadding
					
					setNeedsLayout()
				}
			}
		}
	}
	
	// MARK: Initializers
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		initState()
		
		clipsToBounds = true
		cleanUp()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	// MARK: Life cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		initState()
		
		clipsToBounds = true
		cleanUp()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		cleanUp()
	}
	
	private func initState() {
		backgroundColor = .clear
		selectionStyle = .none
		separatorInset = UIEdgeInsets(top: 0, left: CGFloat.greatestFiniteMagnitude,
									  bottom: 0, right: 0)
	}
	
	// MARK: Setup
	
	private func cleanUp() {
		self.constraints.forEach { removeConstraint($0) }
		self.subviews.forEach { $0.removeFromSuperview() }
		
		headerView = nil
		card = nil
		
		bottomPadding = 0.0
	}
	
	private func setUp(card: TimelineCard, headerStrings: (NSAttributedString, NSAttributedString?)?, customHeaderView: UIView?) {
		
		if let customHeader = customHeaderView {
			headerView = customHeader
		} else if let title = headerStrings?.0 {
			headerView = SimpleTimelineItemHeader(width: bounds.width,
												  title: title, subtitle: headerStrings?.1 ?? NSAttributedString(string: ""))
		}
		
		if let headerView = headerView { addHeader(headerView) }
		
		addCard(card)
		
		contentView.setNeedsLayout()
	}
	
	func setUp(customHeaderView: UIView,
	           card: TimelineCard) {
		
		setUp(card: card, headerStrings: nil, customHeaderView: customHeaderView)
	}
	
	func setUp(title: NSAttributedString, subtitle: NSAttributedString? = nil,
	           card: TimelineCard) {
		
		setUp(card: card, headerStrings: (title, subtitle), customHeaderView: nil)
	}
	
	func setUp(card: TimelineCard) {
		setUp(card: card, headerStrings: nil, customHeaderView: nil)
	}
	
	// MARK: Layout
	
	private func addHeader(_ header: UIView) {
		header.frame = CGRect(origin: .zero, size: header.bounds.size)
		self.addSubview(header)
		
		let constraints: [NSLayoutConstraint] = [
			NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: header, attribute: .top, multiplier: 1, constant: 0),
			NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: header, attribute: .leading, multiplier: 1, constant: 0),
			NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: header, attribute: .trailing, multiplier: 1, constant: 0),
			NSLayoutConstraint(item: header, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: header.bounds.height)
		]
		
		constraints.forEach { $0.isActive = true }
	}
	
	private func addCard(_ card: TimelineCard) {
		self.card = card
		
		card.reload()
		
		card.frame = CGRect(origin: CGPoint(x: 0.0, y: (headerView?.frame.origin.y ?? 0.0) + (headerView?.frame.height ?? 0.0)),
		                    size: card.bounds.size)
		
		self.insertSubview(card, at: subviews.count)
		
		let constraints: [NSLayoutConstraint] = [
			NSLayoutConstraint(item: headerView ?? self, attribute: headerView != nil ? .bottom : .top, relatedBy: .equal, toItem: card, attribute: .top, multiplier: 1, constant: 0),
			NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: card, attribute: .leading, multiplier: 1, constant: 0),
			NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: card, attribute: .trailing, multiplier: 1, constant: 0),
			NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: card, attribute: .bottom, multiplier: 1, constant: bottomPadding),
			NSLayoutConstraint(item: card, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: card.bounds.size.height)
		]
		
		constraints.forEach { $0.isActive = true }
	}
}

/// Vertically layouted feed with `TimelineCard` objects presented. It uses table view internally to offer memory-efficient reusability, which makes it possible to build feed consisting of large amount of cards (for example, one card per day and total of 365 cards in feed).

public class TimelineFeed: UIView, UITableViewDataSource, UITableViewDelegate, TimelineCardEventsHandler {
	// MARK: Properties
	
	private var cardsContainer = UITableView()
	
	// MARK: Appearance
	
	var paddingBetweenCards: CGFloat = 20.0 {
		didSet {
			reloadData()
		}
	}
	
	// MARK: Source
	
	var dataSource: TimelineFeedDataSource? = nil
	
	// MARK: Delegate
	
	var delegate: TimelineFeedDelegate? = nil
	
	// MARK: Initializers
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		backgroundColor = .clear
		
		cardsContainer.frame = bounds
		cardsContainer.backgroundColor = .clear
		cardsContainer.rowHeight = UITableViewAutomaticDimension
		cardsContainer.estimatedRowHeight = frame.height
		
		cardsContainer.dataSource = self
		cardsContainer.delegate = self
		
		cardsContainer.register(TimelineFeedCell.self, forCellReuseIdentifier: String(describing: TimelineFeedCell.self))
		cardsContainer.tableFooterView = UIView(frame: .zero)
		cardsContainer.showsVerticalScrollIndicator = false
		
		addSubview(cardsContainer)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: Life cycle
	
	override public func willMove(toSuperview newSuperview: UIView?) {
		super.willMove(toSuperview: newSuperview)
	}
	
	// MARK: Displaying data
	
	func reloadData() {
		guard let _ = dataSource else { return }
		cardsContainer.reloadData()
	}
	
	// MARK: UITableViewDataSource
	
	public func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let dataSource = dataSource else { return 0 }
		return Int(dataSource.numberOfCards(in: self))
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineFeedCell.self), for: indexPath) as! TimelineFeedCell
		
		guard let dataSource = dataSource else { return cell }
		
		if indexPath.row < Int(dataSource.numberOfCards(in: self) - 1) {
			cell.bottomPadding = paddingBetweenCards
		} else {
			cell.bottomPadding = 0.0
		}
		
		let card = dataSource.card(at: Int(indexPath.row), in: self)
		card.source = dataSource.elementsForTimelineCard(at: Int(indexPath.row), containerWidth: card.descriptionContentWidthLimit)
		
		card.eventsHandler = self
		
		if let customHeader = dataSource.headerViewForCard(at: Int(indexPath.row), in: self) {
			cell.setUp(customHeaderView: customHeader, card: card)
		} else if let headerInfo = dataSource.titleAndSubtitle(at: Int(indexPath.row), in: self) {
			cell.setUp(title: headerInfo.0, subtitle: headerInfo.1, card: card)
		} else {
			cell.setUp(card: card)
		}
		
		return cell
	}
	
	// MARK: UITableViewDelegate
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
	}
	
	// MARK: TimelineCardEventsHandler
	
	public func didSelectElement(at index: Int, in timelineCard: TimelineCard) {
		guard let cell = (cardsContainer.visibleCells as? [TimelineFeedCell])?.flatMap({ return $0.card == timelineCard ? $0 : nil }).first, let cardIndex = cardsContainer.indexPath(for: cell)?.row else { return }
		
		delegate?.didSelectElement(at: index, timelineCardIndex: cardIndex)
	}
	
	public func didSelectSubElement(at index: (Int, Int), in timelineCard: TimelineCard) {
		guard let cell = (cardsContainer.visibleCells as? [TimelineFeedCell])?.flatMap({ return $0.card == timelineCard ? $0 : nil }).first, let cardIndex = cardsContainer.indexPath(for: cell)?.row else { return }
		
		delegate?.didSelectSubElement(at: index, timelineCardIndex: cardIndex)
	}
	
	public func didTouchHeaderView(_ headerView: UIView, in timelineCard: TimelineCard) {
		guard let cell = (cardsContainer.visibleCells as? [TimelineFeedCell])?.flatMap({ return $0.card == timelineCard ? $0 : nil }).first, let cardIndex = cardsContainer.indexPath(for: cell)?.row else { return }
		
		delegate?.didTouchHeaderView(headerView, timelineCardIndex: cardIndex)
	}
	
	public func didTouchFooterView(_ footerView: UIView, in timelineCard: TimelineCard) {
		guard let cell = (cardsContainer.visibleCells as? [TimelineFeedCell])?.flatMap({ return $0.card == timelineCard ? $0 : nil }).first, let cardIndex = cardsContainer.indexPath(for: cell)?.row else { return }
		
		delegate?.didTouchFooterView(footerView, timelineCardIndex: cardIndex)
	}
}

//
//  Utils.swift
//  TimelineCardDemo
//
//  Created by 0xNSHuman on 30/11/2017.
//

import Foundation
import UIKit

func randomImage() -> UIImage {
	return UIImage(named: "icon_\(arc4random() % 5)") ?? UIImage()
}

func randomPastelColor() -> UIColor {
	let randomColorGenerator = { ()-> CGFloat in
		CGFloat(arc4random() % 256 ) / 256
	}
	
	let red: CGFloat = randomColorGenerator()
	let green: CGFloat = randomColorGenerator()
	let blue: CGFloat = randomColorGenerator()
	
	return UIColor(red: red, green: green, blue: blue, alpha: 1)
}

func randomString(length: Int, capitalized: Bool = true) -> String {
	// The more spaces are in alphabet -- the higher chance to use one
	let alphabet : NSString = "                 abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	let alphabetCount = UInt32(alphabet.length)
	
	var randomString = ""
	
	for _ in 0 ..< length {
		let rand = arc4random_uniform(alphabetCount)
		var nextChar = alphabet.character(at: Int(rand))
		randomString += NSString(characters: &nextChar, length: 1) as String
	}
	
	randomString = randomString.trimmingCharacters(in: CharacterSet(charactersIn: " "))
	return capitalized ? randomString.capitalized : randomString
}

func stringFromDate(_ date: Date, format: String) -> String? {
	let formatter = DateFormatter()
	formatter.dateFormat = format
	return formatter.string(from: date)
}

func alert(title: String, text: String, handler: (() -> Void)? = nil) -> UIAlertController {
	let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
	alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {_ in handler?() }))
	return alert
}

func animate(block: @escaping () -> Void, with delay: Double = 0.0) {
	DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay, execute: {
		UIView.animate(withDuration: 0.25, animations: {
			block()
		})
	})
}

public extension UIImage {
	public func applying(tintColor color: UIColor) -> UIImage{
		UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
		let context: CGContext = UIGraphicsGetCurrentContext()!
		context.translateBy(x: 0, y: self.size.height)
		context.scaleBy(x: 1.0, y: -1.0)
		context.setBlendMode(CGBlendMode.normal)
		let rect: CGRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
		context.clip(to: rect, mask: self.cgImage!)
		color.setFill()
		context.fill(rect);
		let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
		UIGraphicsEndImageContext();
		return newImage;
	}
}

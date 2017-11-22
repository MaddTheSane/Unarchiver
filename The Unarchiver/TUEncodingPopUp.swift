//
//  TUEncodingPopUp.swift
//  The Unarchiver
//
//  Created by C.W. Betts on 11/22/17.
//

import Cocoa
import XADMaster.XADString
import XADMasterSwift

class TUEncodingPopUp: NSPopUpButton {

	@objc func buildEncodingList() {
		buildEncodingList(matching: nil)
	}
	
	@objc func buildEncodingListWithAutoDetect() {
		buildEncodingList(matching: nil)
		
		menu?.addItem(NSMenuItem.separator())
		
		let item = NSMenuItem()
		item.title = NSLocalizedString("Detect automatically", comment: "Option in the encoding pop-up to detect the encoding automatically")
		item.tag = 0
		menu?.addItem(item)
	}
	
	@objc func buildEncodingListWithDefaultEncoding() {
		buildEncodingList(matching: nil)
		
		menu?.insertItem(NSMenuItem.separator(), at: 0)
		
		let item = NSMenuItem()
		item.title = NSLocalizedString("Default encoding", comment: "Option in the password encoding pop-up to use the default encoding")
		item.tag = 0
		menu?.insertItem(item, at: 0)
	}
	
	@objc(buildEncodingListMatchingXADString:)
	func buildEncodingList(matching string: XADStringProtocol?) {
		removeAllItems()
		var normalattrs = [NSAttributedStringKey : Any]()
		var smallattrs = [NSAttributedStringKey : Any]()
		if string != nil {
			normalattrs.reserveCapacity(2)
			smallattrs.reserveCapacity(2)
			
			normalattrs[.font] = NSFont.menuFont(ofSize: NSFont.systemFontSize)
			smallattrs[.font] = NSFont.menuFont(ofSize: NSFont.smallSystemFontSize)
			
			let maxWidth = TUEncodingPopUp.maximumEncodingNameWidth(attributes: normalattrs)
			
			let paraStyle = NSMutableParagraphStyle()
			paraStyle.tabStops = [NSTextTab(textAlignment: .left, location: maxWidth + 10)]
			
			normalattrs[.paragraphStyle] = paraStyle.copy()
			smallattrs[.paragraphStyle] = paraStyle.copy()
		}
		
		for encdict in TUEncodingPopUp.encodings {
			let preSwiftEnc = encdict["Encoding"] as! UInt
			let encoding = String.Encoding(rawValue: preSwiftEnc)
			
			if let string = string, !string.canDecode(withEncoding: encoding) {
				continue
			}
			
			let encodingName = encdict["Name"] as! String
			let item = NSMenuItem()
			
			if let string = string {
				guard let decoded = string.string(withEncoding: encoding), TUSanityCheckString(decoded) else {
					continue
				}
				
				let preAttrStr = "\(encodingName)\t\u{27a4} \(decoded)"
				let attrStr = NSMutableAttributedString(string: preAttrStr, attributes: normalattrs)
				
				let tabRange = preAttrStr.range(of: "\t")!
				let smallStrRange = tabRange.lowerBound ..< preAttrStr.endIndex
				attrStr.setAttributes(smallattrs, range: NSRange(smallStrRange, in: preAttrStr))
				
				item.attributedTitle = attrStr
			} else {
				item.title = encodingName
			}
			
			item.tag = Int(encoding.rawValue)
			menu?.addItem(item)
		}
	}
	
	
	@objc class var encodings: [[String : Any]] {
		var encodingarray = [[String : Any]]()
		let allCFEncs = CFStringGetListOfAvailableEncodings()!
		var curentEncPos = allCFEncs
		while curentEncPos.pointee != kCFStringEncodingInvalidId {
			curentEncPos = curentEncPos.successor()
		}
		let encodings = UnsafeBufferPointer(start: allCFEncs, count: allCFEncs.distance(to: curentEncPos))
		
		for cfencoding in encodings {
			let encoding = CFStringConvertEncodingToNSStringEncoding(cfencoding)
			let name = String.localizedName(of: String.Encoding(rawValue: encoding))
			
			if encoding == String.Encoding.unicode.rawValue {
				continue
			}
			encodingarray.append(["Name": name,
								  "Encoding": encoding])
		}
		
		return encodingarray.sorted(by: { (lhs, rhs) -> Bool in
			let name1 = lhs["Name"] as! String
			let name2 = rhs["Name"] as! String
			/*BOOL isunicode1=[name1 hasPrefix:@"Unicode"];
			BOOL isunicode2=[name2 hasPrefix:@"Unicode"];
			
			if(isunicode1&&!isunicode2) return NSOrderedAscending;
			else if(!isunicode1&&isunicode2) return NSOrderedDescending;
			else*/ //return [name1 compare:name2 options:NSCaseInsensitiveSearch|NSNumericSearch];
			return name1.compare(name2, options: [.caseInsensitive, .numeric]) == .orderedAscending
		})
	}
	
	@objc(maximumEncodingNameWidthWithAttributes:)
	class func maximumEncodingNameWidth(attributes attrs: [NSAttributedStringKey : Any]? = nil) -> CGFloat {
		var maxwidth: CGFloat = 0
		
		for encdict in TUEncodingPopUp.encodings {
			let name = encdict["Name"] as! String
			let width = name.size(withAttributes: attrs).width
			if width > maxwidth {
				maxwidth = width
			}
		}
		
		return maxwidth
	}
}

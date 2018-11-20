//
//  TUEncodingPopUp.swift
//  The Unarchiver
//
//  Created by C.W. Betts on 11/22/17.
//

import Cocoa
import XADMaster.String

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
			
			let maxWidth = ceil(TUEncodingPopUp.maximumEncodingNameWidth(attributes: normalattrs))
			
			let paraStyle = NSMutableParagraphStyle()
			paraStyle.tabStops = [NSTextTab(textAlignment: .left, location: maxWidth + 10)]
			
			let immPara = paraStyle.copy()
			normalattrs[.paragraphStyle] = immPara
			smallattrs[.paragraphStyle] = immPara
		}
		
		for encdict in TUEncodingPopUp.encodings {
			let encoding = encdict.encoding
			
			if let string = string, !string.canDecode(with: encoding) {
				continue
			}
			
			let encodingName = encdict.name
			let item = NSMenuItem()
			
			if let string = string {
				guard let decoded = string.string(with: encoding), TUSanityCheckString(decoded) else {
					continue
				}
				
				let preAttrStr = "\(encodingName)\t\u{27a4} \(decoded)"
				let attrStr = NSMutableAttributedString(string: preAttrStr, attributes: normalattrs)
				
				let tabRange = preAttrStr.range(of: "\t")!
				let smallStrRange = tabRange.lowerBound ..< preAttrStr.endIndex
				let smallStrNSRange = NSRange(smallStrRange, in: preAttrStr)
				attrStr.setAttributes(smallattrs, range: smallStrNSRange)
				
				item.attributedTitle = attrStr
			} else {
				item.title = encodingName
			}
			
			item.tag = Int(encoding.rawValue)
			menu?.addItem(item)
		}
	}
	
	class var encodings: [(name: String, encoding: String.Encoding)] {
		let encodings: UnsafeBufferPointer<CFStringEncoding> = {
			let allCFEncs = CFStringGetListOfAvailableEncodings()!
			var curentEncPos = allCFEncs
			while curentEncPos.pointee != kCFStringEncodingInvalidId {
				curentEncPos = curentEncPos.successor()
			}

			return UnsafeBufferPointer(start: allCFEncs, count: allCFEncs.distance(to: curentEncPos))
		}()
		
		let encodingarray = encodings.compactMap { (cfencoding) -> (name: String, encoding: String.Encoding)? in
			let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfencoding))
			if encoding == .unicode {
				return nil
			}
			let name = String.localizedName(of: encoding)
			
			return (name, encoding)
		}
		
		return encodingarray.sorted(by: { (lhs, rhs) -> Bool in
			let name1 = lhs.name
			let name2 = rhs.name
			/*BOOL isunicode1=[name1 hasPrefix:@"Unicode"];
			BOOL isunicode2=[name2 hasPrefix:@"Unicode"];
			
			if(isunicode1&&!isunicode2) return NSOrderedAscending;
			else if(!isunicode1&&isunicode2) return NSOrderedDescending;
			else*/ //return [name1 compare:name2 options:NSCaseInsensitiveSearch|NSNumericSearch];
			let ret = name1.compare(name2, options: [.caseInsensitive, .numeric])
			return ret == .orderedAscending
		})
	}
	
	@objc(maximumEncodingNameWidthWithAttributes:)
	class func maximumEncodingNameWidth(attributes attrs: [NSAttributedStringKey : Any]? = nil) -> CGFloat {
		var maxwidth: CGFloat = 0
		
		for encdict in TUEncodingPopUp.encodings {
			let name = encdict.name
			let width = name.size(withAttributes: attrs).width
			if width > maxwidth {
				maxwidth = width
			}
		}
		
		return maxwidth
	}
}

//
//  FeedProtocol.swift
//  Account
//
//  Created by Maurice Parker on 11/15/19.
//  Copyright © 2019 Ranchero Software, LLC. All rights reserved.
//

import Foundation
import RSCore

public enum ReadFilterType {
	case read
	case none
	case alwaysRead
}

public protocol FeedProtocol: ItemIdentifiable, ArticleFetcher, DisplayNameProvider, UnreadCountProvider {

	var account: Account? { get }
	var defaultReadFilterType: ReadFilterType { get }
	
}

public extension FeedProtocol {
	
	func readFiltered(readFilterEnabledTable: [ItemIdentifier: Bool]) -> Bool {
		guard defaultReadFilterType != .alwaysRead else {
			return true
		}
		if let itemID = itemID, let readFilterEnabled = readFilterEnabledTable[itemID] {
			return readFilterEnabled
		} else {
			return defaultReadFilterType == .read
		}

	}
	
}

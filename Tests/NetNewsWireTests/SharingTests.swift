//
//  SharingTests.swift
//  NetNewsWireTests
//
//  Created by Mathijs Bernson on 23/08/2019.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import Articles
import XCTest

@testable import NetNewsWire

class SharingTests: XCTestCase {

    func testSharingSubject() {
        let sharingServiceDelegate = SharingServiceDelegate(nil)
        let sharingService = NSSharingService(title: "Chirpy", image: NSImage(size: NSSize.zero), alternateImage: nil, handler: {})

        sharingService.delegate = sharingServiceDelegate
        sharingService.perform(withItems: [
            ArticlePasteboardWriter(article: article(titled: "Immunization")),
        ])

        XCTAssertEqual("Immunization", sharingService.subject)
    }

    func testSharingSubjectMultipleArticles() {
        let sharingServiceDelegate = SharingServiceDelegate(nil)
        let sharingService = NSSharingService(title: "Chirpy", image: NSImage(size: NSSize.zero), alternateImage: nil, handler: {})

        sharingService.delegate = sharingServiceDelegate
        sharingService.perform(withItems: [
            ArticlePasteboardWriter(article: article(titled: "NetNewsWire Status: Almost Beta")),
            ArticlePasteboardWriter(article: article(titled: "No Algorithms Follow-Up")),
        ])

        XCTAssertEqual("NetNewsWire Status: Almost Beta, No Algorithms Follow-Up", sharingService.subject)
    }

    private func article(titled title: String) -> Article {
        let articleId = randomId()
		return Article(accountID: randomID(),
					   articleID: articleId,
					   feed: randomID(),
					   uniqueID: randomID(),
					   title: title,
					   contentHTML: nil,
					   contentText: nil,
					   url: nil,
					   externalURL: nil,
					   summary: nil,
					   imageURL: nil,
					   datePublished: nil,
					   dateModified: nil,
					   authors: nil,
					   status: ArticleStatus(articleID: articleId, read: true, dateArrived: Date())
		)
    }

    private func randomID() -> String {
        return UUID().uuidString
    }

}

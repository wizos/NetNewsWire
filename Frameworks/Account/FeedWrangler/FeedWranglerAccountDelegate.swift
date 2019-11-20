//
//  FeedWranglerAccountDelegate.swift
//  Account
//
//  Created by Jonathan Bennett on 2019-08-29.
//  Copyright © 2019 Ranchero Software, LLC. All rights reserved.
//

import Articles
import RSCore
import RSParser
import RSWeb
import SyncDatabase
import os.log

final class FeedWranglerAccountDelegate: AccountDelegate {
	
	var behaviors: AccountBehaviors = []
	
	var isOPMLImportInProgress = false
	var server: String? = FeedWranglerConfig.clientPath
	var credentials: Credentials? {
		didSet {
			caller.credentials = credentials
		}
	}
	
	var accountMetadata: AccountMetadata?
	var refreshProgress = DownloadProgress(numberOfTasks: 0)
	
	private let caller: FeedWranglerAPICaller
	private let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Feed Wrangler")
	private let database: SyncDatabase
	
	init(dataFolder: String, transport: Transport?) {
		if let transport = transport {
			caller = FeedWranglerAPICaller(transport: transport)
		} else {
			let sessionConfiguration = URLSessionConfiguration.default
			sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
			sessionConfiguration.timeoutIntervalForRequest = 60.0
			sessionConfiguration.httpShouldSetCookies = false
			sessionConfiguration.httpCookieAcceptPolicy = .never
			sessionConfiguration.httpMaximumConnectionsPerHost = 1
			sessionConfiguration.httpCookieStorage = nil
			sessionConfiguration.urlCache = nil
			
			if let userAgentHeaders = UserAgent.headers() {
				sessionConfiguration.httpAdditionalHeaders = userAgentHeaders
			}
			
			let session = URLSession(configuration: sessionConfiguration)
			caller = FeedWranglerAPICaller(transport: session)
		}
		
		database = SyncDatabase(databaseFilePath: dataFolder.appending("/DB.sqlite3"))
	}
	
	func accountWillBeDeleted(_ account: Account) {
		fatalError()
	}
	
	func refreshAll(for account: Account, completion: @escaping (Result<Void, Error>) -> Void) {
		refreshProgress.addToNumberOfTasksAndRemaining(6)
		
		self.refreshCredentials(for: account) {
			self.refreshProgress.completeTask()
			self.refreshSubscriptions(for: account) { result in
				self.refreshProgress.completeTask()
				
				switch result {
				case .success:
					self.sendArticleStatus(for: account) { result in
						self.refreshProgress.completeTask()
						
						switch result {
						case .success:
							self.refreshArticleStatus(for: account) { result in
								self.refreshProgress.completeTask()
								
								switch result {
								case .success:
									self.refreshArticles(for: account) { result in
										self.refreshProgress.completeTask()
										
										switch result {
										case .success:
											self.refreshMissingArticles(for: account) { result in
												self.refreshProgress.completeTask()
												
												switch result {
												case .success:
													DispatchQueue.main.async {
														completion(.success(()))
													}
												
												case .failure(let error):
													completion(.failure(error))
												}
											}
										
										case .failure(let error):
											completion(.failure(error))
										}
									}
								
								case .failure(let error):
									completion(.failure(error))
								}
							}
						
						case .failure(let error):
							completion(.failure(error))
						}
					}
				
				case .failure(let error):
					completion(.failure(error))
				}
			}
		}
	}
	
	func cancelAll(for account: Account) {
		fatalError()
	}
	
	func refreshCredentials(for account: Account, completion: @escaping (() -> Void)) {
		os_log(.debug, log: log, "Refreshing credentials...")
		// MARK: TODO
		credentials = try? account.retrieveCredentials(type: .feedWranglerToken)
		completion()
	}
	
	func refreshSubscriptions(for account: Account, completion: @escaping ((Result<Void, Error>) -> Void)) {
		os_log(.debug, log: log, "Refreshing subscriptions...")
		caller.retrieveSubscriptions { result in
			switch result {
			case .success(let subscriptions):
				self.syncFeeds(account, subscriptions)
				completion(.success(()))
				
			case .failure(let error):
				os_log(.debug, log: self.log, "Failed to refresh subscriptions: %@", error.localizedDescription)
				completion(.failure(error))
			}
			
		}
	}
	
	func refreshArticles(for account: Account, page: Int = 0, completion: @escaping ((Result<Void, Error>) -> Void)) {
		os_log(.debug, log: log, "Refreshing articles, page: %d...", page)
		
		caller.retrieveFeedItems(page: page) { result in
			switch result {
			case .success(let items):
				self.syncFeedItems(account, items) {
					if items.count == 0 {
						completion(.success(()))
					} else {
						self.refreshArticles(for: account, page: (page + 1), completion: completion)
					}
				}

			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	func refreshMissingArticles(for account: Account, completion: @escaping ((Result<Void, Error>)-> Void)) {
		os_log(.debug, log: log, "Refreshing missing articles...")
		let group = DispatchGroup()
		
		let fetchedArticleIDs = account.fetchArticleIDsForStatusesWithoutArticles()
		let articleIDs = Array(fetchedArticleIDs)
		let chunkedArticleIDs = articleIDs.chunked(into: 100)
		
		for chunk in chunkedArticleIDs {
			group.enter()
			self.caller.retrieveEntries(articleIDs: chunk) { result in
				switch result {
				case .success(let entries):
					self.syncFeedItems(account, entries) {
						group.leave()
					}
				
				case .failure(let error):
					os_log(.error, log: self.log, "Refresh missing articles failed: %@", error.localizedDescription)
					group.leave()
				}
			}
		}
		
		group.notify(queue: DispatchQueue.main) {
			self.refreshProgress.completeTask()
			os_log(.debug, log: self.log, "Done refreshing missing articles.")
			completion(.success(()))
		}
	}
	
	func sendArticleStatus(for account: Account, completion: @escaping ((Result<Void, Error>) -> Void)) {
		os_log(.debug, log: log, "Sending article status...")
		
		let syncStatuses = database.selectForProcessing()
		let articleStatuses = Dictionary(grouping: syncStatuses, by: { $0.articleID })
		let group = DispatchGroup()
		
		articleStatuses.forEach { articleID, statuses in
			group.enter()
			caller.updateArticleStatus(articleID, statuses) {
				group.leave()
			}
			
		}
		
		group.notify(queue: DispatchQueue.main) {
			os_log(.debug, log: self.log, "Done sending article statuses.")
			completion(.success(()))
		}
	}
	
	func refreshArticleStatus(for account: Account, completion: @escaping ((Result<Void, Error>) -> Void)) {
		os_log(.debug, log: log, "Refreshing article status...")
		let group = DispatchGroup()
		
		group.enter()
		caller.retrieveAllUnreadFeedItems { result in
			switch result {
			case .success(let items):
				self.syncArticleReadState(account, items)
				group.leave()
				
			case .failure(let error):
				os_log(.info, log: self.log, "Retrieving unread entries failed: %@.", error.localizedDescription)
				group.leave()
			}
		}
		
		// starred
		group.enter()
		caller.retrieveAllStarredFeedItems { result in
			switch result {
			case .success(let items):
				self.syncArticleStarredState(account, items)
				group.leave()
				
			case .failure(let error):
				os_log(.info, log: self.log, "Retrieving starred entries failed: %@.", error.localizedDescription)
				group.leave()
			}
		}
		
		group.notify(queue: DispatchQueue.main) {
			os_log(.debug, log: self.log, "Done refreshing article statuses.")
			completion(.success(()))
		}
	}
	
	func importOPML(for account: Account, opmlFile: URL, completion: @escaping (Result<Void, Error>) -> Void) {
		fatalError()
	}
	
	func addFolder(for account: Account, name: String, completion: @escaping (Result<Folder, Error>) -> Void) {
		fatalError()
	}
	
	func renameFolder(for account: Account, with folder: Folder, to name: String, completion: @escaping (Result<Void, Error>) -> Void) {
		fatalError()
	}
	
	func removeFolder(for account: Account, with folder: Folder, completion: @escaping (Result<Void, Error>) -> Void) {
		fatalError()
	}
	
	func createWebFeed(for account: Account, url: String, name: String?, container: Container, completion: @escaping (Result<WebFeed, Error>) -> Void) {
		refreshProgress.addToNumberOfTasksAndRemaining(3)
		
		self.refreshCredentials(for: account) {
			self.refreshProgress.completeTask()
			self.caller.addSubscription(url: url) { result in
				self.refreshProgress.completeTask()
				self.caller.addSubscription(url:  url) { result in
					self.refreshProgress.completeTask()
				
					switch result {
					case .success:
						let feed = account.createWebFeed(with: name, url: url, webFeedID: url, homePageURL: url)
						completion(.success(feed))
							
					case .failure(let error):
						completion(.failure(error))
					}
				}
			}
		}
	}
	
	func renameWebFeed(for account: Account, with feed: WebFeed, to name: String, completion: @escaping (Result<Void, Error>) -> Void) {
		refreshProgress.addToNumberOfTasksAndRemaining(2)
		
		self.refreshCredentials(for: account) {
			self.refreshProgress.completeTask()
			self.caller.renameSubscription(feedID: feed.webFeedID, newName: name) { result in
				self.refreshProgress.completeTask()
				
				switch result {
				case .success:
					DispatchQueue.main.async {
						feed.editedName = name
						completion(.success(()))
					}
					
				case .failure(let error):
					DispatchQueue.main.async {
						let wrappedError = AccountError.wrappedError(error: error, account: account)
						completion(.failure(wrappedError))
					}
				}
			}
		}
	}
	
	func addWebFeed(for account: Account, with: WebFeed, to container: Container, completion: @escaping (Result<Void, Error>) -> Void) {
		fatalError()
	}
	
	func removeWebFeed(for account: Account, with feed: WebFeed, from container: Container, completion: @escaping (Result<Void, Error>) -> Void) {
		refreshProgress.addToNumberOfTasksAndRemaining(2)
		
		self.refreshCredentials(for: account) {
			self.refreshProgress.completeTask()
			self.caller.removeSubscription(feedID: feed.webFeedID) { result in
				self.refreshProgress.completeTask()
				
				switch result {
				case .success:
					DispatchQueue.main.async {
						account.clearWebFeedMetadata(feed)
						account.removeWebFeed(feed)
						completion(.success(()))
					}
					
				case .failure(let error):
					DispatchQueue.main.async {
						let wrappedError = AccountError.wrappedError(error: error, account: account)
						completion(.failure(wrappedError))
					}
				}
			}
		}
	}
	
	func moveWebFeed(for account: Account, with feed: WebFeed, from: Container, to: Container, completion: @escaping (Result<Void, Error>) -> Void) {
		fatalError()
	}
	
	func restoreWebFeed(for account: Account, feed: WebFeed, container: Container, completion: @escaping (Result<Void, Error>) -> Void) {
		fatalError()
	}
	
	func restoreFolder(for account: Account, folder: Folder, completion: @escaping (Result<Void, Error>) -> Void) {
		fatalError()
	}
	
	func markArticles(for account: Account, articles: Set<Article>, statusKey: ArticleStatus.Key, flag: Bool) -> Set<Article>? {
		let syncStatuses = articles.map { SyncStatus(articleID: $0.articleID, key: statusKey, flag: flag)}
		database.insertStatuses(syncStatuses)
		
		if database.selectPendingCount() > 0 {
			sendArticleStatus(for: account) { _ in
					// do it in the background
			}
		}
		
		return account.update(articles, statusKey: statusKey, flag: flag)
	}
	
	func accountDidInitialize(_ account: Account) {
		credentials = try? account.retrieveCredentials(type: .feedWranglerToken)
	}
	
	static func validateCredentials(transport: Transport, credentials: Credentials, endpoint: URL? = nil, completion: @escaping (Result<Credentials?, Error>) -> Void) {
		let caller = FeedWranglerAPICaller(transport: transport)
		caller.credentials = credentials
		caller.validateCredentials() { result in
			DispatchQueue.main.async {
				completion(result)
			}
		}
	}
}

// MARK: Private
private extension FeedWranglerAccountDelegate {
	
	func syncFeeds(_ account: Account, _ subscriptions: [FeedWranglerSubscription]) {
		assert(Thread.isMainThread)
		let feedIds = subscriptions.map { String($0.feedID) }
		
		let feedsToRemove = account.topLevelWebFeeds.filter { !feedIds.contains($0.webFeedID) }
		account.removeFeeds(feedsToRemove)

		var subscriptionsToAdd = Set<FeedWranglerSubscription>()
		subscriptions.forEach { subscription in
			let subscriptionId = String(subscription.feedID)
			
			if let feed = account.existingWebFeed(withWebFeedID: subscriptionId) {
				feed.name = subscription.title
				feed.editedName = nil
				feed.homePageURL = subscription.siteURL
				feed.subscriptionID = nil // MARK: TODO What should this be?
			} else {
				subscriptionsToAdd.insert(subscription)
			}
		}
		
		subscriptionsToAdd.forEach { subscription in
			let feedId = String(subscription.feedID)
			let feed = account.createWebFeed(with: subscription.title, url: subscription.feedURL, webFeedID: feedId, homePageURL: subscription.siteURL)
			feed.subscriptionID = nil
			account.addWebFeed(feed)
		}
	}
	
	func syncFeedItems(_ account: Account, _ feedItems: [FeedWranglerFeedItem], completion: @escaping (() -> Void)) {
		let parsedItems = feedItems.map { (item: FeedWranglerFeedItem) -> ParsedItem in
			let itemID = String(item.feedItemID)
			// let authors = ...
			let parsedItem = ParsedItem(syncServiceID: itemID, uniqueID: itemID, feedURL: String(item.feedID), url: nil, externalURL: item.url, title: item.title, contentHTML: item.body, contentText: nil, summary: nil, imageURL: nil, bannerImageURL: nil, datePublished: item.publishedDate, dateModified: item.updatedDate, authors: nil, tags: nil, attachments: nil)
			
			return parsedItem
		}
		
		let feedIDsAndItems = Dictionary(grouping: parsedItems, by: { $0.feedURL }).mapValues { Set($0) }
		account.update(webFeedIDsAndItems: feedIDsAndItems, defaultRead: true, completion: completion)
	}
	
	func syncArticleReadState(_ account: Account, _ unreadFeedItems: [FeedWranglerFeedItem]) {
		let unreadServerItemIDs = Set(unreadFeedItems.map { String($0.feedItemID) })
		let unreadLocalItemIDs = account.fetchUnreadArticleIDs()
		
		// unread if unread on server
		let unreadDiffItemIDs = unreadServerItemIDs.subtracting(unreadLocalItemIDs)
		let unreadFoundArticles = account.fetchArticles(.articleIDs(unreadDiffItemIDs))
		account.update(unreadFoundArticles, statusKey: .read, flag: false)
		
		let unreadFoundItemIDs = Set(unreadFoundArticles.map { $0.articleID })
		let missingArticleIDs = unreadDiffItemIDs.subtracting(unreadFoundItemIDs)
		account.ensureStatuses(missingArticleIDs, true, .read, false)

		let readItemIDs = unreadLocalItemIDs.subtracting(unreadServerItemIDs)
		let readArtices = account.fetchArticles(.articleIDs(readItemIDs))
		account.update(readArtices, statusKey: .read, flag: true)
		
		let foundReadArticleIDs = Set(readArtices.map { $0.articleID })
		let readMissingIDs = readItemIDs.subtracting(foundReadArticleIDs)
		account.ensureStatuses(readMissingIDs, true, .read, true)
	}
	
	func syncArticleStarredState(_ account: Account, _ unreadFeedItems: [FeedWranglerFeedItem]) {
		let unreadServerItemIDs = Set(unreadFeedItems.map { String($0.feedItemID) })
		let unreadLocalItemIDs = account.fetchUnreadArticleIDs()
		
		// starred if start on server
		let unreadDiffItemIDs = unreadServerItemIDs.subtracting(unreadLocalItemIDs)
		let unreadFoundArticles = account.fetchArticles(.articleIDs(unreadDiffItemIDs))
		account.update(unreadFoundArticles, statusKey: .starred, flag: true)
		
		let unreadFoundItemIDs = Set(unreadFoundArticles.map { $0.articleID })
		let missingArticleIDs = unreadDiffItemIDs.subtracting(unreadFoundItemIDs)
		account.ensureStatuses(missingArticleIDs, true, .starred, true)

		let readItemIDs = unreadLocalItemIDs.subtracting(unreadServerItemIDs)
		let readArtices = account.fetchArticles(.articleIDs(readItemIDs))
		account.update(readArtices, statusKey: .starred, flag: false)
		
		let foundReadArticleIDs = Set(readArtices.map { $0.articleID })
		let readMissingIDs = readItemIDs.subtracting(foundReadArticleIDs)
		account.ensureStatuses(readMissingIDs, true, .starred, false)
	}
	
	func syncArticleState(_ account: Account, key: ArticleStatus.Key, flag: Bool, serverFeedItems: [FeedWranglerFeedItem]) {
		let serverFeedItemIDs = serverFeedItems.map { String($0.feedID) }
		
		// todo generalize this logic
	}
}

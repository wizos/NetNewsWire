# iOS Release Notes

### 6.1.4 TestFlight build 6120 - 1 July 2023

Build using Xcode 14.3.1 so the app won’t crash on launch on iOS 13.

### 6.1.4 TestFlight build 6119 - 30 June 2023

Remove Reddit from Settings. Remove Reddit API code.

## 6.1.3 TestFlight build 6118 - 23 June 2023

Fix release notes URL: it’s now https://github.com/Ranchero-Software/NetNewsWire/releases/

This build was released to the App Store.

### 6.1.3 TestFlight build 6117 - 18 June 2023

Show Reddit shutoff alert to people using Reddit integration.

### 6.1.2 TestFlight build 6116 - 19 Mar 2023

Revise Twitter alert to not mention any dates
Update copyright to 2023

### 6.1.1 TestFlight build 6114 - 5 Feb 2023

Remove Twitter integration. Include alert that Twitter integration was removed.

### 6.1.1 TestFlight build 6113 - 22 Jan 2023

Fix a crashing bug when fetching data for the widget

### 6.1.1 TestFlight build 6112 - 16 Jan 2023

Add some feeds back to defaults — now an even 10 feeds

### 6.1.1 TestFlight build 6111 - 8 Jan 2023 (didn’t actually go out via TestFlight)

Fixed a crashing bug in the Feeds screen
Cut way down on number of default feeds, added BBC World News

### 6.1 Release build 6110 - 9 Nov 2022

Changes since 6.0.1…

Article themes. Several themes ship with the app, and you can create your own. You can change the theme in Preferences.
Fixed a bug that could prevent BazQux syncing when an article may not contain all the info we expect
Fixed a bug that could prevent Feedly syncing when marking a large number of articles as read
Disallow creation of iCloud account in the app if iCloud and iCloud Drive aren’t both enabled
Added links to iCloud Syncing Limitations & Solutions on iCloud Account Management UI
Copy URLs using repaired, rather than raw, feed links
Fixed bug showing quote tweets that only included an image
Video autoplay is now disallowed
Article view now supports RTL layout
Fixed a few crashing bugs
Fixed a layout bug that could happen on returning to the Feeds list
Fixed a bug where go-to-feed might not properly expand disclosure triangles
Prevented the Delete option from showing in the Edit menu on the Article View
Fixed Widget article icon lookup bug


### 6.1 TestFlight build 6109 - 31 Oct 2022

Enhanced Widget integration to make counts more accurate
Enhanced Widget integration to make make it more efficient and save on battery life

### 6.1 TestFlight build 6108 - 28 Oct 2022

Fixed a bug that could prevent BazQux syncing when an article may not contain all the info we expect
Fixed a bug that could prevent Feedly syncing when marking a large number of articles as read
Prevent Widget integration from running while in the background to remove some crashes

### 6.1 TestFlight build 6107 - 28 Sept 2022

Added links to iCloud Syncing Limitations & Solutions on iCloud Account Management UI
Prevented the Delete option from showing in the Edit menu on the Article View
Greatly reduced the possibility of a background crash caused by Widget integration
Fixed Widget article icon lookup bug

### 6.1 TestFlight build 6106 - 9 July 2022

Fix a bug where images wouldn’t appear in the widget

### 6.1 TestFlight build 6105 - 6 July 2022

Write widget icons to the shared container
Make crashes slightly less likely when building up widget data

### 6.1 TestFlight build 6104 - 6 April 2022

Building on a new machine and making sure all’s well
Moved built-in themes to the app bundle so they’re always up to date
Fixed a crash in the Feeds list related to updating the feed image
Fixed a layout bug that could happen on returning to the Feeds list
Fixed a bug where go-to-feed might not properly expand disclosure triangles

### 6.1 TestFlight build 6103 - 25 Jan 2022

Fixed regression with keyboard shortcuts.
Fixed crashing bug adding an account.

### 6.1 TestFlight build 6102 - 23 Jan 2022

Article themes. Several themes ship with the app, and you can create your own. You can change the theme in Preferences.
Copy URLs using repaired, rather than raw, feed links.
Disallow creation of iCloud account in the app if iCloud and iCloud Drive aren’t both enabled.
Fixed bug showing quote tweets that only included an image.
Video autoplay is now disallowed.
Article view now supports RTL layout.

### 6.0.2 Release - 15 Oct 2021

Makes a particular crash on startup, that happens only on iPad, far less likely.

### 6.0.2 TestFlight build 610 - 25 Sep 2021

Fixed bug with state restoration on launch (bug introduced in previous TestFlight build)

### 6.0.1 TestFlight build 608 - 28 Aug 2021

Fixed our top crashing bug — it could happen when updating a table view

### 6.0.1 TestFlight build 607 - 21 Aug 2021

Fixed bug where BazQux-synced feeds might stop updating
Fixed bug where words prepended with $ wouldn’t appear in Twitter feeds
Fixed bug where newlines would be just a space in Twitter feeds
Fixed a crashing bug in Twitter rendering
Fixed bug where hitting b key to open in browser wouldn’t always work
Fixed a crashing bug due to running code off the main thread that needed to be on the main thread
Fixed bug where article unread indicator could have wrong alpha in specific circumstances
Fixed bug using right arrow key to move focus to Article view
Fixed bug where long press could trigger a crash
Fixed bug where external URLs in Feedbin feeds might be lost
Fixed bug where favicons wouldn’t be found when a home page URL has non-ASCII characters
Fixed bug where iCloud syncing could stop prematurely when the sync database has records not in the local database
Fixed bug where creating a new folder in iCloud and moving feeds to it wouldn’t sync correctly

### 6.0 TestFlight build 604 - 31 May 2021

This is a final candidate
Updated about NetNewsWire section
Fixed bug where Tweetbot share sheet could be empty
Feedly: fixed bug where your custom name could get lost after moving a feed to a different folder
Twitter: fixed bug handling tweets containing characters made up of multiple scalars
iCloud: added explanation about when sync may be slow

### 6.0 TestFlight build 603 - 16 May 2021

Feedly: handle Feedly API change with return value on deleting a folder
NewsBlur: sync no longer includes items marked as hidden on NewsBlur
FreshRSS: form for adding account now suggests endpoint URL
FreshRSS: improved the error message for when the API URL can’t be found
iCloud: retain existing feeds moved to a folder that doesn’t exist yet (sync ordering issue)
Renamed a Delete Account button to Remove Account
iCloud: skip displaying an error message on deleting a feed that doesn’t exist in iCloud
Preferences: Tweaked text explaining Feed Providers
Feeds list: context menu for smart feeds is back (regression fix)
Feeds list: all smart feeds remain visible despite Hide Read Feeds setting
Article view: fixed zoom issue on iPad on rotation
Article view: fixed bug where mark-read button on toolbar would flash on navigating to an unread article
Article view: made footnote detection more robust
Fixed regression on iPad where timeline and article wouldn’t update after the selected feed was deleted
Sharing: handle feeds where the URL has unencoded space characters (why a feed would do that is beyond our ken)

### 6.0 TestFlight build 602 - 21 April 2021

Inoreader: don’t call it so often, so we don’t go over the API limits
Feedly: handle a specific case where Feedly started not returning a value we expected but didn’t actually need (we were reporting it as an error to the user, but it wasn’t)

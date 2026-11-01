import Foundation

enum Paths {
    static let home = FileManager.default.homeDirectoryForCurrentUser.path
    static let socketDirectory = home + "/Library/Application Support/activity-recall"
    static let socket = socketDirectory + "/socket"
    static let messages = home + "/Library/Messages/chat.db"
    static let calls = home + "/Library/Application Support/CallHistoryDB/CallHistory.storedata"
    static let safari = home + "/Library/Safari/History.db"
    static let photos = home + "/Pictures/Photos Library.photoslibrary/database/Photos.sqlite"
}

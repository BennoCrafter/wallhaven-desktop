import SwiftUI

class User: Codable {
    var username: String
    var group: String
    var avatar: UserAvatar

    init(username: String, group: String, avatar: UserAvatar) {
        self.username = username
        self.group = group
        self.avatar = avatar
    }
}

class UserAvatar: Codable {
    var px200: URL
    var px128: URL
    var px23: URL
    var px20: URL

    init(px200: URL, px128: URL, px23: URL, px20: URL) {
        self.px200 = px200
        self.px128 = px128
        self.px23 = px23
        self.px20 = px20
    }
}

import Foundation

struct ClipConfiguration: Codable {
    var quantity: Int = 10
    var duration: Int = 30
    var baseTitle: String = ""
    var hashtags: String = ""
    var outputFolder: URL?
    
    init(quantity: Int = 10, duration: Int = 30, baseTitle: String = "", hashtags: String = "", outputFolder: URL? = nil) {
        self.quantity = quantity
        self.duration = duration
        self.baseTitle = baseTitle
        self.hashtags = hashtags
        self.outputFolder = outputFolder
    }
}

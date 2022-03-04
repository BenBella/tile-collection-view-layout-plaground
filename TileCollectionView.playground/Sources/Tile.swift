import UIKit

public enum Size: String, Codable {
    case square = "1x1"
    case fullWidth = "2x1"
    case doubleHeight = "1x2"
    case halfHeight =  "1x0.5"
}

public protocol Tile {
    var size: Size { get set }
    var color: UIColor { get }
}

public final class GameTile: Tile {
    public var size: Size
    public var color: UIColor
    
    public init(size: Size) {
        self.size = size
        self.color = UIColor.random
    }
}

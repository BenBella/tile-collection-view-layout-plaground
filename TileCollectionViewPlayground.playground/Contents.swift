import UIKit
import PlaygroundSupport

enum LayoutSegmentStyle {
    case oneFullWidth
    case twoDoubleHeights
    case twoSquares
    case twoHalfHeightsAndOneSquare
    case oneSquareAndTwoHalfHeights
    case fourHalfHeights
}

public final class TileCollectionViewLayout: UICollectionViewLayout {
 
    var contentBounds = CGRect.zero
    var cachedAttributes = [UICollectionViewLayoutAttributes]()
    let sidePadding: CGFloat = 16.0
    let cellSpacing: CGFloat = 8.0
    public var tiles: [Tile]
    private var segments: [LayoutSegmentStyle]
    
    public init(tiles: [Tile]) {
        self.tiles = tiles
        self.segments = Self.prepareSegments(tiles: tiles)
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func prepare() {
        super.prepare()
        
        guard let collectionView = collectionView else { return }

        // Reset cached information.
        cachedAttributes.removeAll()
        contentBounds = CGRect(origin: .zero, size: collectionView.bounds.size)
    
        var currentIndex = 0
        var lastFrame: CGRect = .zero
        let collectionViewWidth = collectionView.bounds.size.width
        let segmentWidth = collectionViewWidth - (2 * sidePadding)
        let segmentHeight = segmentWidth / 2
        
        for segment in segments {
            var segmentFrame = CGRect(x: sidePadding, y: lastFrame.maxY + 1.0, width: segmentWidth, height: segmentHeight)
            var segmentRects = [(segment: CGRect, item: CGRect)]()
            
            switch segment {
            case .oneFullWidth:
                segmentRects = [(segment: segmentFrame,
                                 item: segmentFrame.insetBy(dx: sidePadding, dy: sidePadding))]
            case .twoDoubleHeights:
                segmentFrame.size.height = segmentHeight * 2
                let horizontalSlices = segmentFrame.dividedIntegral(fraction: 0.5, from: .minXEdge)
                let hFirst = horizontalSlices.first
                let hSecond = horizontalSlices.second
                segmentRects = [(segment: hFirst,
                                 item: hFirst.insetBy(dx: sidePadding, dy: sidePadding)),
                                (segment: hSecond,
                                 item: hSecond.insetBy(dx: sidePadding, dy: sidePadding))]
                
            case .twoSquares:
                let horizontalSlices = segmentFrame.dividedIntegral(fraction: 0.5, from: .minXEdge)
                let hFirst = horizontalSlices.first
                let hSecond = horizontalSlices.second
                segmentRects = [(segment: hFirst,
                                 item: hFirst.insetBy(dx: sidePadding, dy: sidePadding)),
                                (segment: hSecond,
                                 item: hSecond.insetBy(dx: sidePadding, dy: sidePadding))]
                
            case .twoHalfHeightsAndOneSquare:
                let horizontalSlices = segmentFrame.dividedIntegral(fraction: (0.5), from: .minXEdge)
                let verticalSlices = horizontalSlices.first.dividedIntegral(fraction: 0.5, from: .minYEdge)
                let vFirst = verticalSlices.first
                let vSecond = verticalSlices.second
                let hSecond = horizontalSlices.second
                segmentRects = [(segment: vFirst,
                                 item: vFirst.insetBy(dx: sidePadding, dy: sidePadding)),
                                (segment: vSecond,
                                 item: vSecond.insetBy(dx: sidePadding, dy: sidePadding)),
                                (segment:  hSecond,
                                 item:  hSecond.insetBy(dx: sidePadding, dy: sidePadding))]
                
            case .oneSquareAndTwoHalfHeights:
                let horizontalSlices = segmentFrame.dividedIntegral(fraction: (0.5), from: .minXEdge)
                let verticalSlices = horizontalSlices.second.dividedIntegral(fraction: 0.5, from: .minYEdge)
                let hFirst = horizontalSlices.first
                let vFirst = verticalSlices.first
                let vSecond = verticalSlices.second
                segmentRects = [(segment: hFirst, item: hFirst.insetBy(dx: sidePadding, dy: sidePadding)),
                                (segment: vFirst, item: vFirst.insetBy(dx: sidePadding, dy: sidePadding)),
                                (segment: vSecond, item: vSecond.insetBy(dx: sidePadding, dy: sidePadding))]
                
            case .fourHalfHeights:
                let horizontalSlices = segmentFrame.dividedIntegral(fraction: (0.5), from: .minXEdge)
                let verticalSlices1 = horizontalSlices.first.dividedIntegral(fraction: 0.5, from: .minYEdge)
                let verticalSlices2 = horizontalSlices.second.dividedIntegral(fraction: 0.5, from: .minYEdge)
                let vFirst1 = verticalSlices1.first
                let vSecond1 = verticalSlices1.second
                let vFirst2 = verticalSlices2.first
                let vSecond2 = verticalSlices2.second
                segmentRects =  [(segment: vFirst1, item: vFirst1.insetBy(dx: sidePadding, dy: sidePadding)),
                                 (segment: vSecond1, item: vSecond1.insetBy(dx: sidePadding, dy: sidePadding)),
                                 (segment: vFirst2, item: vFirst2.insetBy(dx: sidePadding, dy: sidePadding)),
                                 (segment: vSecond2, item: vSecond2.insetBy(dx: sidePadding, dy: sidePadding))]
            }
            
            // Create and cache layout attributes for calculated frames.
            for rect in segmentRects {
                let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: currentIndex, section: 0))
                attributes.frame = rect.item
                
                cachedAttributes.append(attributes)
                contentBounds = contentBounds.union(lastFrame)
                
                currentIndex += 1
                lastFrame = rect.segment
            }
        }
    }
    
    public override var collectionViewContentSize: CGSize {
        return contentBounds.size
    }
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return false }
        return !newBounds.size.equalTo(collectionView.bounds.size)
    }
    
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cachedAttributes[indexPath.item]
    }
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributesArray = [UICollectionViewLayoutAttributes]()
        
        // Find any cell that sits within the query rect.
        guard let lastIndex = cachedAttributes.indices.last,
              let firstMatchIndex = binSearch(rect, start: 0, end: lastIndex) else { return attributesArray }
        
        // Starting from the match, loop up and down through the array until all the attributes
        // have been added within the query rect.
        for attributes in cachedAttributes[..<firstMatchIndex].reversed() {
            guard attributes.frame.maxY >= rect.minY else { break }
            attributesArray.append(attributes)
        }
        
        for attributes in cachedAttributes[firstMatchIndex...] {
            guard attributes.frame.minY <= rect.maxY else { break }
            attributesArray.append(attributes)
        }
        
        return attributesArray
    }
    
    private static func prepareSegments(tiles: [Tile]) -> [LayoutSegmentStyle] {
        var segments: [LayoutSegmentStyle] = []
        var stack: [Tile] = []
        
        for tile in tiles {
            stack.append(tile)
            
            switch stack.count {
            case 1:
                if stack[0].size == .fullWidth {
                    segments.append(.oneFullWidth)
                    stack.removeAll()
                }
            case 2:
                if stack[0].size == .square && stack[1].size == .square {
                    segments.append(.twoSquares)
                    stack.removeAll()
                }
                else if stack[0].size == .doubleHeight && stack[1].size == .doubleHeight {
                    segments.append(.twoDoubleHeights)
                    stack.removeAll()
                }
            case 3:
                if stack[0].size == .square && stack[1].size == .halfHeight && stack[2].size == .halfHeight {
                    segments.append(.oneSquareAndTwoHalfHeights)
                    stack.removeAll()
                }
                else if stack[0].size == .halfHeight && stack[1].size == .halfHeight && stack[2].size == .square {
                    segments.append(.twoHalfHeightsAndOneSquare)
                    stack.removeAll()
                }
            case 4:
                if stack[0].size == .halfHeight && stack[1].size == .halfHeight && stack[2].size == .halfHeight && stack[3].size == .halfHeight {
                    segments.append(.fourHalfHeights)
                    stack.removeAll()
                }
            default:
                break
            }
        }
        
        return segments
    }
    
    func binSearch(_ rect: CGRect, start: Int, end: Int) -> Int? {
        if end < start { return nil }
        
        let mid = (start + end) / 2
        let attr = cachedAttributes[mid]
        
        if attr.frame.intersects(rect) {
            return mid
        } else {
            if attr.frame.maxY < rect.minY {
                return binSearch(rect, start: (mid + 1), end: end)
            } else {
                return binSearch(rect, start: start, end: (mid - 1))
            }
        }
    }
}

class Cell: UICollectionViewCell {
    var identifier: String?
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
       
        configView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configView()
    }
    
    override func prepareForReuse() {
        self.identifier = nil
    }
    
    private func configView() {
        self.clipsToBounds = false
        self.backgroundColor = .gray
        self.layer.cornerRadius = 10
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 0.0)
        self.layer.shadowRadius = 10
        self.layer.shadowOpacity = 0.2
    }
}

class TilesViewController: UICollectionViewController {
    var tiles: [Tile] = []
    override init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(collectionViewLayout: layout)
        self.tiles = (layout as? TileCollectionViewLayout)?.tiles ?? []
        self.collectionView?.backgroundColor  = .white
        self.collectionView?.register(Cell.self, forCellWithReuseIdentifier: "cell")
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView?.reloadData()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tiles.count
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! Cell
        
        let tile = self.tiles[indexPath.row]
        cell.backgroundColor = tile.color
        return cell
    }
}

let tiles = [
    GameTile(size: .doubleHeight),
    GameTile(size: .doubleHeight),
    GameTile(size: .fullWidth),
    GameTile(size: .square),
    GameTile(size: .square),
    GameTile(size: .square),
    GameTile(size: .halfHeight),
    GameTile(size: .halfHeight),
    GameTile(size: .square),
    GameTile(size: .square),
    GameTile(size: .halfHeight),
    GameTile(size: .halfHeight),
    GameTile(size: .halfHeight),
    GameTile(size: .halfHeight),
    GameTile(size: .halfHeight),
    GameTile(size: .halfHeight),
    GameTile(size: .square),
]


let tileLayout = TileCollectionViewLayout(tiles: tiles)

PlaygroundPage.current.liveView = UINavigationController(rootViewController: TilesViewController(collectionViewLayout: tileLayout))


import Foundation
import SpriteKit

// MARK: - Расширение словаря для чтения JSON
extension Dictionary {
    static func loadJSONFromBundle(filename: String) -> Dictionary<String, AnyObject>? {
        var dataOK: Data
        var dictionaryOK: NSDictionary = NSDictionary()
        if let path = Bundle.main.path(forResource: filename, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: NSData.ReadingOptions()) as Data!
                dataOK = data!
            }
            catch {
                print("Could not load level file: \(filename), error: \(error)")
                return nil
            }
            do {
                let dictionary = try JSONSerialization.jsonObject(with: dataOK, options: JSONSerialization.ReadingOptions()) as AnyObject!
                dictionaryOK = (dictionary as! NSDictionary as? Dictionary<String, AnyObject>)! as NSDictionary
            }
            catch {
                print("Level file '\(filename)' is not valid JSON: \(error)")
                return nil
            }
        }
        return dictionaryOK as? Dictionary<String, AnyObject>
    }
}

/// Стуктура, которая необходима для сохранения координат (CGPoint - неподходящий вариант [CGFloat])
public struct Point {
    
    public var column: Int
    public var row: Int
    
    public init(column: Int, row: Int) {
        self.column = column
        self.row = row
    }
}

public struct Scale {
    public var xScale: CGFloat
    public var yScale: CGFloat
    
    public init(xScale: CGFloat, yScale: CGFloat) {
        self.xScale = xScale
        self.yScale = yScale
    }
}

func ==(lhs: Point, rhs: Point) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}

func !=(lhs: Point, rhs: Point) -> Bool {
    return lhs.column != rhs.column || lhs.row != rhs.row
}

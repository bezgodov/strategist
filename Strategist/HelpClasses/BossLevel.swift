import Foundation
import SpriteKit

class BossLevel: NSObject, SKPhysicsContactDelegate {
    
//    let objectBitMask: UInt32 = 0x1 << 1
//    let characterBitMask: UInt32 = 0x1 << 2
    
    enum CollisionTypes: UInt32 {
        case enemy = 1
        case character = 2
        case star = 3
    }
    
    override init() {
        super.init()
        
        Model.sharedInstance.gameScene.physicsWorld.contactDelegate = self
        
        characterSettings()
        
        let directions: [UISwipeGestureRecognizerDirection] = [.right, .left, .up, .down]
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
            gesture.direction = direction
            Model.sharedInstance.gameScene.view!.addGestureRecognizer(gesture)
        }
        
        Timer.scheduledTimer(withTimeInterval: 1.645, repeats: true) { (_) in
            self.newObject()
        }
        
        Timer.scheduledTimer(withTimeInterval: 5.313, repeats: true) { (_) in
            self.newStar()
        }
    }
    
    func characterSettings() {
        Model.sharedInstance.gameScene.character.physicsBody = SKPhysicsBody(rectangleOf: Model.sharedInstance.gameScene.character.size)
        Model.sharedInstance.gameScene.character.physicsBody?.isDynamic = false
        Model.sharedInstance.gameScene.character.physicsBody?.categoryBitMask = CollisionTypes.character.rawValue
        Model.sharedInstance.gameScene.character.physicsBody?.contactTestBitMask = CollisionTypes.enemy.rawValue | CollisionTypes.star.rawValue
        Model.sharedInstance.gameScene.character.physicsBody?.collisionBitMask = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func newObject() {
        let objectsToMove = [ObjectType.bee, ObjectType.spinner]
        
        let randomObject = objectsToMove[Int(arc4random_uniform(UInt32(objectsToMove.count)))]
        createObject(type: randomObject)
        
    }
    
    func newStar() {
        createObject(type: ObjectType.star)
    }
    
    func createObject(type: ObjectType) {
        let randomPos = Point(column: Model.sharedInstance.gameScene.boardSize.column + 3, row: Int(arc4random_uniform(5)))
        
        var sizeKoef: CGFloat = 0.75
        
        switch type {
            case ObjectType.star:
                sizeKoef = 0.5
            default:
                sizeKoef = 0.75
        }
        
        let object = SKSpriteNode(imageNamed: type.spriteName)
        object.position = Model.sharedInstance.gameScene.pointFor(column: randomPos.column, row: randomPos.row)
        object.zPosition = 4
        object.size = CGSize(width: TileWidth * sizeKoef, height: object.size.height / (object.size.width / (TileWidth * sizeKoef)))
        
        object.physicsBody = SKPhysicsBody(rectangleOf: object.size)
        object.physicsBody?.affectedByGravity = false
        object.physicsBody?.collisionBitMask = 0
        object.physicsBody?.contactTestBitMask = CollisionTypes.character.rawValue
        Model.sharedInstance.gameScene.objectsLayer.addChild(object)
        
        objectExtraParams(type: type, object: object)
        
        let moveToPos = Model.sharedInstance.gameScene.pointFor(column: -1, row: randomPos.row)
        let randomSpeed = TimeInterval(CGFloat(arc4random_uniform(3) + 2) + CGFloat(Float(arc4random()) / Float(UINT32_MAX)))
        
        object.run(SKAction.moveTo(x: moveToPos.x, duration: randomSpeed)) {
            object.removeFromParent()
        }
    }
    
    func objectExtraParams(type: ObjectType, object: SKSpriteNode) {
        object.physicsBody?.categoryBitMask = CollisionTypes.enemy.rawValue
        
        if type == ObjectType.spinner {
            object.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi * 2), duration: 1)))
        }
        
        if type == ObjectType.star {
            object.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        print(contact.bodyA.node?.physicsBody?.categoryBitMask)
        print(contact.bodyB.node?.physicsBody?.categoryBitMask)
        if contact.bodyA.node?.physicsBody?.categoryBitMask == CollisionTypes.character.rawValue && contact.bodyB.node?.physicsBody?.categoryBitMask == CollisionTypes.star.rawValue {
            contact.bodyB.node?.removeFromParent()
        }
        
        if contact.bodyB.node?.physicsBody?.categoryBitMask == CollisionTypes.character.rawValue && contact.bodyA.node?.physicsBody?.categoryBitMask == CollisionTypes.star.rawValue {
            contact.bodyA.node?.removeFromParent()
        }
        
        if contact.bodyB.node?.physicsBody?.categoryBitMask == CollisionTypes.character.rawValue && contact.bodyA.node?.physicsBody?.categoryBitMask == CollisionTypes.enemy.rawValue {
            Model.sharedInstance.gameScene.loseLevel()
        }
        
        if contact.bodyA.node?.physicsBody?.categoryBitMask == CollisionTypes.character.rawValue && contact.bodyB.node?.physicsBody?.categoryBitMask == CollisionTypes.enemy.rawValue {
            Model.sharedInstance.gameScene.loseLevel()
        }
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            var point = Model.sharedInstance.gameScene.convertPoint(point: Model.sharedInstance.gameScene.character.position)
            
            if swipeGesture.direction == UISwipeGestureRecognizerDirection.right {
                point.point.column += 1
            }
            if swipeGesture.direction == UISwipeGestureRecognizerDirection.up {
                point.point.row += 1
            }
            if swipeGesture.direction == UISwipeGestureRecognizerDirection.left {
                point.point.column -= 1
            }
            if swipeGesture.direction == UISwipeGestureRecognizerDirection.down {
                point.point.row -= 1
            }
            
            if point.point.column >= 0 && point.point.column < Model.sharedInstance.gameScene.boardSize.column && point.point.row >= 0 && point.point.row < Model.sharedInstance.gameScene.boardSize.row {
                Model.sharedInstance.gameScene.character.run(SKAction.move(to: Model.sharedInstance.gameScene.pointFor(column: point.point.column, row: point.point.row), duration: 0.3), completion: {
                    
                })
            }
        }
    }
}

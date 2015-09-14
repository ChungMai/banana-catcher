import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let ground: Ground = Ground()
    let basketMan: BasketMan = BasketMan()
    
    var touching = false
    var touchLoc = CGPointMake(0, 0)
    
    override func didMoveToView(view: SKView) {
        backgroundColor = bgColor
        addGround()
        addBasketMan()
    }
    
    override func update(currentTime: CFTimeInterval) {
        if (touching) { moveBasketMan() }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        touching = true
        touchLoc = touches.first!.locationInNode(self)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        touchLoc = touches.first!.locationInNode(self)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        touching = false
    }
    
    
    /* Add game elements */
    
    private func addGround() {
        ground.position = CGPoint(x: CGRectGetMidX(self.frame), y: ground.size.height / 2 - 10)
        addChild(ground)
    }
    
    private func addBasketMan() {
        basketMan.position = CGPoint(x: CGRectGetMidX(self.frame), y: self.frame.height + 50)
        addChild(basketMan)
    }
    
    
    /* Move game elements */
    
    private func moveBasketMan() {
        let dx = touchLoc.x - basketMan.position.x
        let mag = abs(dx)
        
        if(mag > 3.0) {
            basketMan.position.x += dx / mag * 5.0
        }
    }
}

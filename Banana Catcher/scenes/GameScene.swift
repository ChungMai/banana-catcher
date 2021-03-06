import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate, CollissionDetector, ThrowSupport {
    
    var props: PropsManager!
    var basketMan: BasketMan!
    var monkey: EvilMonkey!
    var lives: Lives!
    var scoreLabel: ScoreLabel!
    var levelUpLabel: LevelUpLabel!
    var darkener: SKShapeNode!
    
    var touching = false
    var touchLoc = CGPointMake(0, 0)
    
    override func didMoveToView(view: SKView) {
        initPhysics()
        
        score = 0
        
        props = GameProps.init(forScene: self)
        props.add()
        
        basketMan = props.basketMan
        monkey = props.monkey
        lives = props.lives
        scoreLabel = props.scoreLabel
        levelUpLabel = props.levelUpLabel
        darkener = props.darkener
        
        musicPlayer.change("game_1")
        
        Ads.showBanner()
    }
    
    private func initPhysics() {
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVectorMake(0, -5)
        
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: self.frame)
        self.physicsBody?.categoryBitMask = CollisionCategories.EdgeBody

    }
    
    override func update(currentTime: CFTimeInterval) {
        monkey.move(frame.width)
        
        monkeyThrowsSomething()
        
        if touching && !basketMan.isDead() {
            basketMan.move(touchLoc, range: frame.width)
        }
        
        if basketMan.position.y < 0 {
            gameOver()
        }
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
    
    
    // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    // * Collision detection
    // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    
    func didBeginContact(contact: SKPhysicsContact) {
        handleContact(contact: contact,
            onHitBasketMan: throwableHitsBasketMan,
            onHitGround: throwableHitsGround)
    }
    
    
    // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    // * Update states
    // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    
    private func updateScore(points: Int) {
        score += points
        scoreLabel.setScore(score)
    }
    
    private func updateMonkey() {
        let levelBefore = monkey.currentLevel()
        monkey.enrage()
        let currentLevel = monkey.currentLevel()
        
        if currentLevel > levelBefore {
            levelUpLabel.show(currentLevel)
            
            if currentLevel == 5 { musicPlayer.change("game_2") }
            if currentLevel == 10 { musicPlayer.change("game_3") }
            if currentLevel == 15 { musicPlayer.change("game_4") }
            if currentLevel == 20 { musicPlayer.change("game_5") }
                        
            monkey.disable()
            monkey.throwTantrum(dramaticDarkening())
            
            let center = SKAction.moveToX(CGRectGetMidX(frame), duration: 0.5)
            let wait = SKAction.waitForDuration(monkey.currentLevel() < 5 ? 0 : 0.6)
            let frenzy = coconutFrenzyActions()
            let enable = SKAction.runBlock { self.monkey.enable() }
            
            monkey.runAction(SKAction.sequence([center, wait, frenzy, enable]))
        }
    }
    
    private func dramaticDarkening() -> () -> Void {
        let darken = SKAction.fadeAlphaTo(0.8, duration: 0.5)
        let wait = SKAction.waitForDuration(0.8)
        let lighten = SKAction.fadeAlphaTo(0, duration: 0.6)
        
        return { self.darkener.runAction(SKAction.sequence([darken, wait, lighten])) }
    }
    
    private func decrementLives() {
        if lives.isEmpty() {
            monkey.disable()
            basketMan.die()
        }
        else {
            lives.down()
        }
    }
    
    private func incrementLives() {
        lives.up()
    }
    
    
    // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    // * Collission detection callbacks
    // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    
    private func throwableHitsBasketMan(item: Throwable) {
        let pos = item.position
        
        switch item {
        case is Banana:
            bananaHitsBasketMan(pos, GamePoints.BananaCaught)
        
        case is BananaCluster:
            bananaHitsBasketMan(pos, GamePoints.BananaClusterCaught)
            
        case is Coconut, is Banananut, is Heartnut:
            coconutHitsBasketMan(pos, GamePoints.CoconutCaught)

        case is Supernut:
            coconutHitsBasketMan(pos, GamePoints.SupernutCaught)
            
        case is Heart:
            let points = GamePoints.HeartCaught
            
            showCollectPoints(pos, points)
            updateScore(points)
            basketMan.lifeUp()
            incrementLives()
            
        case is Greenmush:
            let points = GamePoints.MushCaught
            
            showCollectPoints(pos, points)
            updateScore(points)
            basketMan.goGreen()
            
        case is Purplemush:
            let points = GamePoints.MushCaught
            
            showCollectPoints(pos, points)
            updateScore(points)
            basketMan.goPurple()
            
        default:
            unexpectedHit(item, receiver: "BasketMan")
        }
        
        item.removeFromParent()
    }
    
    private func bananaHitsBasketMan(pos: CGPoint, _ points: Int) {
        if basketMan.isDead() { return }
        
        showCollectPoints(pos, points)
        updateScore(points)
        basketMan.collect()
        updateMonkey()
    }
    
    private func coconutHitsBasketMan(pos: CGPoint, _ points: Int) {
        if basketMan.isInvincible() || basketMan.isDead() { return }
        
        showCollectPoints(pos, points)
        updateScore(points)
        decrementLives()
        basketMan.ouch()
    }
    
    private func throwableHitsGround(item: Throwable) {
        let pos = item.position
        
        switch item {
        case is Banana:
            let yPos = props.groundLevel + 5
            let splat = SplatBanana(pos: CGPointMake(item.position.x, yPos))
            let points = GamePoints.BananaMissed
            
            showCollectPoints(CGPointMake(pos.x, pos.y + 15), points)
            updateScore(points)
            basketMan.frown()
            
            addChild(splat)
            item.removeFromParent()
            
        case is BananaCluster:
            let yPos = props.groundLevel + 5
            let splat = SplatBananaCluster(pos: CGPointMake(item.position.x, yPos))
            let points = GamePoints.BananaClusterMissed
            
            showCollectPoints(CGPointMake(pos.x, pos.y + 15), points)
            updateScore(points)
            basketMan.frown()
            
            addChild(splat)
            item.removeFromParent()
            
        case is Coconut, is Banananut, is Heartnut:
            let yPos = props.groundLevel + 30
            let spawnPos = CGPointMake(item.position.x, yPos)
            
            switch item {
                
            case is Banananut: throwSpawnedItem(Banana.spawnAt(spawnPos))
                
            case is Heartnut: throwSpawnedItem(Heart.spawnAt(spawnPos))
                
            default: break
            }

            addChild(Brokenut(pos: spawnPos))
            item.removeFromParent()
            
        case is Supernut:
            let yPos = props.groundLevel + 30
            let spawnPos = CGPointMake(item.position.x, yPos)
            
            var numSpawns: Int = monkey.currentLevel() / 5
            if numSpawns < 1 { numSpawns = 1 }
            
            for _ in 1...numSpawns {
                throwSpawnedItem(Coconut.spawnAt(spawnPos))
            }

            let broke = Superbroke(pos: spawnPos)
            
            addChild(broke)
            item.removeFromParent()
            
        case is Heart, is Greenmush, is Purplemush:
            let fadeOut = SKAction.fadeOutWithDuration(0.5)
            let remove = SKAction.runBlock { item.removeFromParent() }
            
            item.runAction(SKAction.sequence([fadeOut, remove]))
            
        default:
            unexpectedHit(item, receiver: "the ground")
        }
    }

    private func showCollectPoints(pos: CGPoint, _ points: Int) {
        let label = CollectPointLabel(points: points, x: pos.x, y: pos.y)
        
        addChild(label)
    }
    
    private func unexpectedHit(item: Throwable, receiver: String) {
        fatalError("Unexpected item (\(item)) hit \(receiver)!")
    }
    
    
    // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    // * Dun dun duuuun!
    // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    
    private func gameOver() {        
        let scene = GameOverScene(size: size)
        scene.scaleMode = scaleMode
        
        let transitionType = SKTransition.flipVerticalWithDuration(0.5)
        view?.presentScene(scene,transition: transitionType)
    }
}

import SpriteKit

class TutorialScene: SKScene, SKPhysicsContactDelegate {
    
    private var hWidth: CGFloat = 0.0
    private var helper: TutorialStageHelper!
    
    let ground: Ground = Ground()
    let basketMan: BasketMan = BasketMan()
    let monkey: EvilMonkey = EvilMonkey()
    
    private var nextButton: SKSpriteNode!
    private var infoLabel:  InfoLabel!
    
    override func didMoveToView(view: SKView) {
        hWidth = size.width / 2
        
        musicPlayer.change("tutorial")

        adjustPhysics()
        addBackgroundImage()
        addGround()
        addDoodads()
        addBasketMan()
        addEvilMonkey()
        addDarkness()
        addLabels()
        addButtons()
        addStageHelper()
    }
        
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touchLocation = touches.first!.locationInNode(self)
        let touchedNode = self.nodeAtPoint(touchLocation)
        
        if(touchedNode.name == ButtonNodes.next) {
            playSound(self, name: "option_select.wav")
            helper.playNextStage()
        }
    }
    
    
    // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    // * Collision detection
    // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    
    func didBeginContact(contact: SKPhysicsContact) {
        CollissionDetector.run(
            contact: contact,
            onHitBasketMan: throwableHitsBasketMan,
            onHitGround: throwableHitsGround)
    }
    
    
    // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    // * Add game elements
    // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    
    private func adjustPhysics() {
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVectorMake(0, -5)
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
        self.physicsBody?.categoryBitMask = CollisionCategories.EdgeBody
    }
    
    private func addBackgroundImage() {
        let background = SKSpriteNode(imageNamed: "background.png")
        background.position = CGPointMake(CGRectGetMidX(frame), background.size.height / 2)
        background.zPosition = -999
        addChild(background)
    }
    
    private func addGround() {
        ground.position = CGPoint(x: hWidth, y: ground.size.height / 2)
        addChild(ground)
    }
    
    private func addDoodads() {
        let groundLevel = ground.size.height
        let cloudGen = CloudGenerator(forScene: self)
        let bushGen = BushGenerator(forScene: self, yBasePos: groundLevel)
        let burriedGen = BurriedGenerator(forScene: self, yBasePos: groundLevel)
        
        [burriedGen, bushGen, cloudGen].forEach { $0.generate() }
    }
    
    private func addBasketMan() {
        basketMan.position = CGPoint(x: hWidth, y: ground.size.height + 10)
        
        addChild(basketMan)
    }
    
    private func addEvilMonkey() {
        monkey.position = CGPoint(x: hWidth, y: size.height - 180)
        
        addChild(monkey)
    }
    
    private func addDarkness() {
        let topDarkness = SKSpriteNode(imageNamed: "darkness_top.png")
        let bottomDarkness = SKSpriteNode(imageNamed: "darkness_bottom.png")
        
        topDarkness.size.height *= 0.5
        bottomDarkness.size.height *= 0.7
        
        topDarkness.position = CGPointMake(hWidth, size.height - topDarkness.size.height / 2)
        bottomDarkness.position = CGPointMake(hWidth, bottomDarkness.size.height / 2 - 50)
        
        [topDarkness, bottomDarkness].forEach {
            $0.zPosition = -600
            addChild($0)
        }
    }
    
    private func addLabels() {
        let zPos: CGFloat = -500
        let header = TutorialLabel(x: hWidth, y: size.height - 45, zPosition: zPos)
        
        infoLabel = InfoLabel(x: hWidth, y: size.height - 100, zPosition: zPos)
        
        addChild(header)
        addChild(infoLabel)
    }
    
    private func addButtons() {
        let buttonGenerator = ButtonGenerator(forScene: self, yBasePos: 40)
        
        buttonGenerator.generate()
        
        nextButton = buttonGenerator.nextButton
    }
    
    private func addStageHelper() {
        helper = TutorialStageHelper(scene: self)
    }
    
    // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    // * Tutorial stageHelper functions
    // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

    func prepareForNextStage(nextButtonTexture: String) {
        infoLabel.clear()
        nextButton.alpha = 0.2
        nextButton.texture = SKTexture(imageNamed: "ok.png")
    }
    
    func enableNextButton() {
        nextButton.alpha = 1.0
    }
    
    func changeInfoLabelText(text: String)  {
        self.infoLabel.changeText(text)
    }
    
    
    func moveToMenuScene() {
        let scene = MenuScene(size: self.size)
        scene.scaleMode = self.scaleMode
        
        self.view?.presentScene(scene, transition: SKTransition.flipVerticalWithDuration(0.5))
    }
    
    
    // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    // * Collission detection callbacks
    // * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    
    private func throwableHitsBasketMan(item: Throwable) {
        switch item {
            
        case is Banana:
            let pos = item.position
            let label = CollectPointLabel(points: GamePoints.BananaCaught, x: pos.x, y: pos.y)
            
            addChild(label)
            basketMan.collect()
            
        case is Coconut:
            basketMan.ouch()
            
        default:
            unexpectedHit(item, receiver: "BasketMan")
        }
        
        item.removeFromParent()
    }
    
    private func throwableHitsGround(item: Throwable) {
        switch item {
            
        case is Banana:
            basketMan.frown()

            item.removeFromParent()
            
        case is Coconut:
            let pos = CGPointMake(item.position.x, ground.size.height + 5)
            let brokenut = Brokenut(pos: pos)
            
            addChild(brokenut)
            
        default:
            unexpectedHit(item, receiver: "the ground")
        }
        
        item.removeFromParent()
    }
    
    private func unexpectedHit(item: Throwable, receiver: String) {
        fatalError("Unexpected item (\(item)) hit \(receiver)!")
    }
}
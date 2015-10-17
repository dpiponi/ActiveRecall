import Foundation
import Darwin

class Deck : NSObject, NSCoding {
    var numCards : Int
    var initCardLevel : Int = 6
    var cardIndices : [Int]
    var cardLevels : [Int]
    var history : [Int] = [Int]()
    var levelHistory : [Int] = [Int]()
    let historyLength : Int = 16
    
    init(numCards n: Int, initCardLevel level: Int) {
        numCards = n
        initCardLevel = level
        cardIndices = [Int](count: n, repeatedValue: 0)
        cardLevels = [Int](count: n, repeatedValue: initCardLevel)
    }
    func resize(newSize: Int) {
        if newSize > numCards {
            // Grow
            cardIndices = cardIndices + Array(numCards..<newSize)
            cardLevels = cardLevels +
                [Int](count: newSize-numCards, repeatedValue: initCardLevel)
            numCards = newSize
        } else if newSize < numCards {
            // Shrink
            cardIndices = cardIndices.filter({ $0 < newSize }) // XXX!
            cardLevels = Array(cardLevels[0..<newSize])
            numCards = newSize
            assert(cardIndices.count == newSize)
            assert(cardLevels.count == newSize)
        }
    }
    func start() {
        for i in 0..<numCards {
            cardIndices[i] = i
            cardLevels[i] = initCardLevel
        }
    }
    func reset() {
        for i in 0..<numCards {
            cardIndices[i] = i
            cardLevels[i] = initCardLevel
        }
        history = [Int]()
        levelHistory = [Int]()
    }
    func dump() {
        print("cards = ", cardIndices)
        print("levels = ", cardLevels)
    }
    convenience required init?(coder decoder: NSCoder) {
        var version : Int = 0
        if decoder.containsValueForKey("version") {
            version = Int(decoder.decodeIntForKey("version"))
        }
        let n = decoder.decodeIntForKey("numCards")
        let level = decoder.decodeIntForKey("initCardLevel")
        self.init(numCards:Int(n), initCardLevel:Int(level))
        self.cardIndices = decoder.decodeObjectForKey("cardIndices") as! [Int]
        self.cardLevels = decoder.decodeObjectForKey("cardLevels") as! [Int]
        if version >= 1 {
            self.history = decoder.decodeObjectForKey("history") as! [Int]
        } else {
            self.history = [Int]()
        }
        if version >= 2 {
            self.levelHistory = decoder.decodeObjectForKey("levelHistory") as! [Int]
        } else {
            self.levelHistory = [Int]()
        }
        
        assert(cardIndices.count == numCards)
        assert(cardLevels.count == numCards)

    }
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeInt(2, forKey:"version")
        coder.encodeInt(Int32(self.numCards), forKey:"numCards")
        coder.encodeInt(Int32(self.initCardLevel), forKey:"initCardLevel")
        coder.encodeObject(self.cardIndices, forKey:"cardIndices")
        coder.encodeObject(self.cardLevels, forKey:"cardLevels")
        coder.encodeObject(self.history, forKey:"history")
        coder.encodeObject(self.levelHistory, forKey:"levelHistory")
    }
    func trimHistory() {
        if history.count > historyLength {
            history.removeRange(historyLength ..< history.count)
            levelHistory.removeRange(historyLength ..< history.count)
        }
    }
    func moveFrontToBack() {
        let currentCard : Int = cardIndices.removeAtIndex(0)
        
        let newIndex : Int = numCards-1
        cardIndices.insert(currentCard, atIndex: newIndex)
        history.insert(newIndex, atIndex: 0)
        levelHistory.insert(cardLevels[currentCard], atIndex: 0)
        trimHistory()
    }
    func correct() {
        let currentCard : Int = cardIndices.removeAtIndex(0)
        
        let newIndex : Int = min(cardLevels[currentCard], numCards-1)
        cardIndices.insert(currentCard, atIndex: newIndex)
        history.insert(newIndex, atIndex: 0)

        levelHistory.insert(cardLevels[currentCard], atIndex: 0)
        trimHistory()
        if cardLevels[currentCard] < numCards {
            cardLevels[currentCard] *= 2
        }
    }
    func incorrect() {
        let currentCard : Int = cardIndices.removeAtIndex(0)
        
        levelHistory.insert(cardLevels[currentCard], atIndex: 0)
        cardLevels[currentCard] = 8
        
        let newIndex : Int = min(cardLevels[currentCard], numCards-1)
        cardIndices.insert(currentCard, atIndex: newIndex)
        history.insert(newIndex, atIndex: 0)
        trimHistory()
    }
    func undo() {
        if history.count > 0 {
            let lastCard = cardIndices.removeAtIndex(history[0])
            cardIndices.insert(lastCard, atIndex: 0)
            history.removeAtIndex(0)
            levelHistory.removeAtIndex(0)
        }
    }
    //
    // Fisher-Yates
    //
    func shuffle() {
        if numCards > 1 {
            let currentCard = cardIndices[0]
            
            for i in (numCards-1).stride(to: 1, by: -1) {
                let j = Int(arc4random_uniform(UInt32(i+1)))
                if i != j {
                    swap(&cardIndices[i], &cardIndices[j])
                }
            }
            
            // Users won't believe it's a real shuffle unless the top card changes
            if cardIndices[0] == currentCard {
                let i : Int = Int(arc4random_uniform(UInt32(numCards)-1))+1
                swap(&cardIndices[0], &cardIndices[i])
            }
            
            history.removeAll()
            levelHistory.removeAll()
        }
    }
}
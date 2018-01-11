ActiveRecall
============

Status
------
This was a nicely working project. But since I wrote it Swift and the iOS libraries have moved on and bit rot has set in. This has convinced me not to bother with iOS programming ever again.

FlashCard App for iOS

This is a minimal flashcard app for iOS. It uses PDF for input. Pages 1 and 2 give the first card, pages 3 and 4 give the second card and so on. An example of a file in this format is the set of [Civics Flash Cards for the Naturalization Test](http://www.uscis.gov/sites/default/files/USCIS/Office%20of%20Citizenship/Citizenship%20Resource%20Center%20Site/Publications/PDFs/M-623_red_slides.pdf).

ActiveRecall doesn't build slide decks. You must provide PDFs from somewhere. For example go to the Civics Flash Cards link above and use "Open in...".

It uses a simple strategy to present cards you don't know more often. Tap on the left of a card to say you don't know it well and it gets put back in the deck near the top. If you think you do know a card tap on the right and it'll get put in the deck further down. Each time you revisit a card and tap on the right it'll get put back further down the deck. Compare with the [Leitner system](https://en.wikipedia.org/wiki/Leitner_system).

![Screen shot](https://raw.github.com/dpiponi/ActiveRecall/master/screenshot.png)

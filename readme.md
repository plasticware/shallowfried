This is an idle game where you run your own donut factory! Sell your donuts and let the cash roll in!

Overview:

When you join the game, you will be assigned to a factory.\
Donuts come out of the oven and will proceed down the conveyor belt.\
When donuts reach the end of the conveyor belt, they are sold.\
After buying some automatic donut makers, you will see a ui element over the oven showing when the next batch of donuts is ready.\
Your factory will place as many donuts as it can fit onto the conveyor belt. If your oven is making donuts faster than your conveyor belt can process them, buy belt speed upgrades!\
(I was originally also going to force players to buy upgrades for how quickly your factory can automatically sell your donuts, but ultimately decided against it.)\
You can compare some basic stats to your fellow players by looking at the wall behind their factories.

Yes, there's a big reset lever in the middle of your factory. Don't pull it. (used for testing purposes)

---

Architecture:

Disclaimer: I was trying to build out the game as quickly as possible, and accrued a lot of technical debt in the process. There are some places, for example, where if I had time to reengineer things, I'd attach listeners to player upgrades, rather than firing out events when a function updates them. I'd also try to mirror more player information onto the client to avoid some extra client/server calls.

Putting that aside, the game can be split into a few major components:\
Player manager: This module holds player stats and events for players joining/leaving.\
Core: This module ticks the main loop for baking donuts and controls factory ownership. It also contains functions for determining upgrade price and effect, as well as other info.\
Factory: Each factory runs its own factory script. Factories spawn and destroy donut objects and contain some information about the player's owned upgrades.

Some game logic is also handled by minor components:\
Donut: Each donut moves itself down the conveyor belt and tracks information about what type of donut it is and what modifiers have been applied to it.\
Upgrade levers: Each upgrade control lever registers itself to its parent factory, which then sets its label correspondingly. Levers fire events when they are pulled, to check if the player has unlocked the corresponding upgrade and whether they can afford it.

---

Extensibility:

It's fairly trivial to add further types of donuts to the game, as new levers can be created and have constants set inside the unity editor. Corresponding entries have to be added to the upgrade information tables in the core module, of course.\
More conveyor belt machines: I currently have a donut glazer machine, and I imagine further adding icing and sprinkles machines. These would not be as trivial, but the proof of concept exists with the glazer.

---

Future work:

One feature I'd like to add is gating some upgrades behind certain prestige levels (e.g. a type of donut that you have to prestige twice in order to unlock).

A feature that would maybe add some more social elements is having pickups spawn in random locations in the world which grant some bonus, maybe 5% of your current cash. Pickup locations would be synchronized on the server so players would be running into each other when trying to claim them.

The game's various ui elements are frankly, not in a good state. One basic improvement would be to have various text billboards rotate toward the camera. Another would be some better text styling, for example having locked text be red on upgrade levers. Also, when spawning billboards for spawning/selling donuts, there is a very noticeable black frame when the billboards are instantiated - whatever I'm doing is clearly not the correct approach.
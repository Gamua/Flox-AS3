Flox SDK - ActionScript 3
=========================

What is Flox?
-------------

Flox is a server backend especially for game developers, providing all the basics you need for a game: analytics, leaderboards, custom entities, and much more. The focus of Flox lies on its scalability (guaranteed by running in the Google App Engine) and ease of use.

While you can communicate with our servers directly via REST, we provide powerful SDKs for the most popular development platforms, including advanced features like offline-support and data caching. With these SDKs, integrating Flox into your game is just a matter of minutes.

More information about Flox can be found here: [Flox, the No-Fuzz Game Backend](http://gamua.com/flox)

How to use the ActionScript 3 SDK
---------------------------------

Just by **starting up Flox**, you will already generate several interesting analytics charts in the web interface.
    
    Flox.init("gameID", "gameKey", "1.0");

With **Events**, you can collect more finegrained data about how players are using your game. Pass custom properties to get a nice visualization of the details.

    Flox.logEvent("GameStarted");
    Flox.logEvent("MenuNavigation", { from: "MainMenu", to: "SettingsMenu" });

To **send and retrieve scores**, first set up a leaderboard in the web interface. Using its ID as an identifier, you are good to go.

    Flox.postScore("default", 999, "Johnny");
    Flox.loadScores("default", TimeScope.ALL_TIME, 
        function onComplete(scores:Array):void
        {
            trace("retrieved " + scores.length + " scores");
        },
        function onError(error:String, cachedScores:Array):void
        {
            trace("error loading scores: " + error);
        });

This is just the tip of the iceberg, though! Use Flox to store **custom Entities** and **query** them, make **Player Logins** via a simple **e-mail verification** or a **social network**, browse your game's **logs**, assign **custom permissions**, and much more.
        
Where to go from here:
----------------------

* Visit [flox.cc](http://www.flox.cc) for more information about Flox.
* Register and download the pre-compiled SDK to get started quickly.

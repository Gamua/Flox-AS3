package com.gamua.flox
{
    import com.gamua.flox.events.QueueEvent;
    
    import flash.events.Event;
    
    import starling.unit.UnitTest;
    
    public class ScoreTest extends UnitTest
    {
        public override function setUp():void
        {
            Constants.initFlox();
        }
        
        public override function tearDown():void
        {
            Flox.shutdown();
        }
        
        public function testSubmitScores():void
        {
            var score:int = Math.random() * 1000;
            Flox.postScore(Constants.LEADERBOARD_ID, score, "hugo");
        }
        
        public function testJsonName(onComplete:Function):void
        {
            var leaderboardID:String = "json";
            var date:Date = new Date();
            var score:int = int(date.time / 10000);
            var data:Object = { name: "hugo", score: score };
            
            Flox.addEventListener(QueueEvent.QUEUE_PROCESSED, onQueueProcessed);
            Flox.postScore(leaderboardID, score, JSON.stringify(data));
            
            function onQueueProcessed(event:Event):void
            {
                Flox.removeEventListener(QueueEvent.QUEUE_PROCESSED, onQueueProcessed);
                Flox.loadScores(leaderboardID, TimeScope.ALL_TIME, onScoresLoaded, onScoresError);
            }
            
            function onScoresLoaded(scores:Array):void
            {
                assert(scores[0].value == score);
                onComplete();
            }
            
            function onScoresError(error:String):void
            {
                fail("Could not load score with JSON player name: " + error); 
                onComplete();
            }
        }
        
        public function testRetrieveScores(onComplete:Function):void
        {
            var serverScores:Array;
            
            Flox.clearCache();
            Flox.loadScores(Constants.LEADERBOARD_ID, TimeScope.ALL_TIME,
                onScoresLoaded, onScoresError);
            
            function onScoresLoaded(scores:Array):void
            {
                assertNotNull(scores, "retrieved 'null' scores");
                serverScores = scores;
                
                // now try again and get scores from cache
                Flox.service.alwaysFail = true;
                Flox.loadScores(Constants.LEADERBOARD_ID, TimeScope.ALL_TIME,
                                onCacheScoresLoaded, onCacheScoresError);
            }
            
            function onScoresError(error:String):void
            {
                fail("Could not get scores from server: " + error);
                onComplete();
            }
            
            function onCacheScoresLoaded(scores:Array):void
            {
                fail("Received scores even though 'alwaysFail' is enabled");
                onComplete();
            }
            
            function onCacheScoresError(error:String, cachedScores:Array):void
            {
                assertNotNull(cachedScores, "retrieved 'null' scores");
                assertEqualObjects(cachedScores, serverScores);
                onComplete();
            }
        }
        
        public function testPostAndLoadScoresWithDifferentNames(onComplete:Function):void
        {
            var highscore:int;
            var leaderboardID:String = Constants.LEADERBOARD_ID;
            Flox.postScore(leaderboardID, 100, "Tony"); 
            Flox.loadScores(leaderboardID, TimeScope.THIS_WEEK, onLoadScoresComplete, onError);
            
            function onLoadScoresComplete(scores:Array):void
            {
                assert(scores.length > 0, "didn't receive any score");
                highscore = scores[0].value;
                
                Flox.postScore(leaderboardID, highscore + 1, "Tony");
                Flox.postScore(leaderboardID, highscore + 1, "Tina");

                Flox.loadScores(leaderboardID, TimeScope.THIS_WEEK, 
                    onLoadMoreScoresComplete, onError);
            }
            
            function onLoadMoreScoresComplete(scores:Array):void
            {
                var tony:Score = scores[0].playerName == "Tony" ? scores[0] : scores[1];
                var tina:Score = scores[0].playerName == "Tina" ? scores[0] : scores[1];
                
                assertEqual(tony.value, tina.value, "wrong scores");
                assertEqual(highscore + 1, tony.value, "wrong score");
                assertEqual(tony.playerName, "Tony", "wrong name");
                assertEqual(tina.playerName, "Tina", "wrong name");
                assertEqual(2, tina.country.length, "wrong country code");
                assertEqual(2, tony.country.length, "wrong country code");
                onComplete();
            }
            
            function onError(error:String):void
            {
                fail("error loading leaderboard: " + error);
                onComplete();
            }
        }
        
        public function testOffline(onComplete:Function):void
        {
            Flox.service.alwaysFail = true;
            Flox.clearCache();
            Flox.loadScores(Constants.LEADERBOARD_ID, TimeScope.ALL_TIME,
                onScoresLoaded, onScoresError);
            
            function onScoresLoaded(scores:Array):void
            {
                fail("Received scores even though 'alwaysFail' is enabled");
                onComplete();
            }
            
            function onScoresError(error:String, cachedScores:Array):void
            {
                assertNull(cachedScores);
                onComplete();
            }
        }
        
        public function testLeaderboardOfFriends(onComplete:Function):void
        {
            var leaderboardID:String = Constants.LEADERBOARD_ID;
            var playerIDs:Array = [];
            var values:Array    = [100, 80, 60];
            var names:Array     = ["first", "second", "third"];
            
            for (var i:int=0; i<values.length; ++i)
            {
                Player.logout();
                Flox.postScore(leaderboardID, values[i], names[i]);
                playerIDs.push(Player.current.id);
            }
            
            Flox.loadScores(leaderboardID, playerIDs, onScoresLoaded, onScoresError);
            
            function onScoresLoaded(scores:Array):void
            {
                if (playerIDs.length != scores.length)
                {
                    fail("wrong number of scores returned: " + scores.length);
                    onComplete();
                }
                else
                {
                    for (var i:int=0; i<playerIDs.length; ++i)
                    {
                        assertEqual(playerIDs[i], scores[i].playerId,   "wrong player id");
                        assertEqual(    names[i], scores[i].playerName, "wrong player name");
                        assertEqual(   values[i], scores[i].value,      "wrong score");
                        
                        assertEqual(2, scores[i].country.length, "wrong country code");
                        assertEqual(scores[i].date.fullYearUTC, new Date().fullYearUTC, "wrong year");
                    }
                    
                    onComplete();
                }
            }
            
            function onScoresError(error:String, cachedScores:Array):void
            {
                fail("could not load friend scores! " + error);
                onComplete();
            }
        }
    }
}
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
            
            function onScoresLoaded(scores:Vector.<Score>):void
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
            var serverScores:Vector.<Score>;
            
            Flox.clearCache();
            Flox.loadScores(Constants.LEADERBOARD_ID, TimeScope.ALL_TIME,
                onScoresLoaded, onScoresError);
            
            function onScoresLoaded(scores:Vector.<Score>):void
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
            
            function onCacheScoresLoaded(scores:Vector.<Score>):void
            {
                fail("Received scores even though 'alwaysFail' is enabled");
                onComplete();
            }
            
            function onCacheScoresError(error:String, cachedScores:Vector.<Score>):void
            {
                assertNotNull(cachedScores, "retrieved 'null' scores");
                assertEqualObjects(cachedScores, serverScores);
                onComplete();
            }
        }
        
        public function testOffline(onComplete:Function):void
        {
            Flox.service.alwaysFail = true;
            Flox.clearCache();
            Flox.loadScores(Constants.LEADERBOARD_ID, TimeScope.ALL_TIME,
                onScoresLoaded, onScoresError);
            
            function onScoresLoaded(scores:Vector.<Score>):void
            {
                fail("Received scores even though 'alwaysFail' is enabled");
                onComplete();
            }
            
            function onScoresError(error:String, cachedScores:Vector.<Score>):void
            {
                assertNull(cachedScores);
                onComplete();
            }
        }
    }
}
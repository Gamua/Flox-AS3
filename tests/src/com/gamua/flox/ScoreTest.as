package com.gamua.flox
{
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
        
        public function testRetrieveScores(onComplete:Function):void
        {
            Flox.loadScores(Constants.LEADERBOARD_ID, TimeScope.ALL_TIME,
                onScoresLoaded, onScoresError);
            
            function onScoresLoaded(scores:Vector.<Score>):void
            {
                assertNotNull(scores, "retrieved 'null' scores");
                onComplete();
            }
            
            function onScoresError(error:String):void
            {
                fail("Could not get scores from server: " + error);
                onComplete();
            }
        }
    }
}
package tests
{
    import com.gamua.flox.Flox;
    import com.gamua.flox.HttpManager;
    import com.gamua.flox.Leaderboard;
    import com.gamua.flox.Score;
    import com.gamua.flox.SortOrder;
    import com.gamua.flox.TimeScope;
    
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    
    import starling.unit.UnitTest;

    public class LeaderboardTest extends UnitTest
    {
        public override function setUp():void
        {
            Flox.init(Constants.GAME_ID, Constants.GAME_KEY);
            HttpManager.clearCache();
            HttpManager.clearQueue();
        }
        
        public override function tearDown():void
        {
            Flox.shutdown();
        }
        
        public function testConstructor():void
        {
            var id:String = "id";
            var sortOrder:String = SortOrder.LOW_TO_HIGH;
            var leaderboard:Leaderboard = new Leaderboard(id, sortOrder);
            assertEqual(id, leaderboard.id);
            assertEqual(TimeScope.ALL_TIME, leaderboard.timeScope);
            assertEqual(0, leaderboard.length);
            assertEqual(sortOrder, leaderboard.sortOrder);
        }
        
        public function testAddScores():void
        {
            var leaderboard:Leaderboard = new Leaderboard("12");
            var scores:Array = [
                new Score("tonyID", "tony", 100, new Date(), "en"),
                new Score("carlID", "carl", 50,  new Date(), "at"),
                new Score("bellID", "bell", 150, new Date(), "us")
            ];
            
            leaderboard.addScores(scores);
            assertEqual(scores.length, leaderboard.length);
            
            leaderboard.addScores(new Score("anneID", "anne", 200, new Date(), "de"));
            assertEqual(scores.length+1, leaderboard.length);
            
            assertEqual("anne", leaderboard.getScoreAt(0).playerName);
            assertEqual("bell", leaderboard.getScoreAt(1).playerName);
            assertEqual("tony", leaderboard.getScoreAt(2).playerName);
            assertEqual("carl", leaderboard.getScoreAt(3).playerName);
        }
        
        public function testLoadDefaultLeaderboard(onComplete:Function):void
        {
            Flox.loadLeaderboard("default", TimeScope.ALL_TIME, onSuccess, onError);
            
            function onSuccess(leaderboard:Leaderboard):void
            {
                assertNotNull(leaderboard);
                assertEqual(TimeScope.ALL_TIME, leaderboard.timeScope);
                onComplete();
            }
            
            function onError(error:String):void
            {
                fail("Could not load leaderboards from server: " + error);
                onComplete();
            }
        }
        
        public function testSubmitAndRetrieveScores(onComplete:Function):void
        {
            // find out current leader
            var topScore:int;
            var intervalID:uint;
            
            Flox.loadLeaderboard("default", TimeScope.ALL_TIME, onLbLoaded, onLbError);
            
            function onLbLoaded(leaderboard:Leaderboard):void
            {
                topScore = 0;
                if (leaderboard.length > 0)
                    topScore = leaderboard.getScoreAt(0).value;
                
                Flox.postScore("default", topScore + 1, "testSubmitAndRetrieveScores");
                intervalID = setInterval(onScorePosted, 200);
            }
            
            function onLbError(error:String):void
            {
                fail("could not load Leaderboard: " + error);
                onComplete();
            }
            
            function onScorePosted():void
            {
                if (HttpManager.queueLength == 0)
                {   
                    clearInterval(intervalID);
                    Flox.loadLeaderboard("default", TimeScope.TODAY, onLbLoaded2, onLbError); 
                }
            }
            
            function onLbLoaded2(leaderboard:Leaderboard):void
            {
                assert(leaderboard.getScoreAt(0).value == topScore + 1);
                onComplete();
            }
        }
        
    }
}
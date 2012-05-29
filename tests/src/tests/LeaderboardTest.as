package tests
{
    import com.gamua.flox.Flox;
    import com.gamua.flox.Leaderboard;
    import com.gamua.flox.Score;
    import com.gamua.flox.SortOrder;
    import com.gamua.flox.TimeScope;
    
    import flash.utils.setTimeout;
    
    import starling.unit.UnitTest;

    public class LeaderboardTest extends UnitTest
    {
        private static const GAME_KEY:String = "7e143737-6af5-4c66-a261-ea0e0fe7e047"; //"b375e3dc-429a-4bdd-8856-1652a405fe20";
        private static const GAME_ID:String  = "unit-test-app";
        
        public override function setUp():void
        {
            Flox.init(GAME_ID, GAME_KEY);
        }
        
        public override function tearDown():void
        {
            Flox.shutdown();
        }
        
        /** TODO:
         * 
         *  - Request auf nicht-existentes leaderboard sollte speziellen HTTP status liefern
         * 
         */
        
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
                new Score("carlID", "carl", 50, new Date(), "at"),
                new Score("bellID", "bell", 150, new Date(), "us")
            ]
            
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
    }
}
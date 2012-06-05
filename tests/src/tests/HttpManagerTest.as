package tests
{
    import com.gamua.flox.HttpManager;
    
    import flash.utils.clearInterval;
    import flash.utils.clearTimeout;
    import flash.utils.setInterval;
    import flash.utils.setTimeout;
    
    import starling.unit.UnitTest;
    
    public class HttpManagerTest extends UnitTest
    {
        public override function setUp():void
        {
            HttpManager.init(Constants.BASE_URL);
            HttpManager.clearCache();
            HttpManager.clearQueue();
        }
        
        public function testErrorPickup(onComplete:Function):void
        {
            var url:String = Constants.createGameUrl("leaderboards/invalid/scores/allTime.xml");
            HttpManager.getXml(url, null, onGetComplete, onGetError);
            
            function onGetComplete():void
            {
                fail("complete handler called where GET should have failed");
                onComplete();
            }
            
            function onGetError(error:String):void
            {
                assertNotNull(error);
                assert(error.length != 0)
                onComplete();
            }
        }
        
        public function testCache(onComplete:Function):void
        {
            var url:String = Constants.createLeaderboardUrl("scores", "allTime.xml");
            var xmlString:String;
            
            HttpManager.getXml(url, null, onFirstGet, onError);
            
            function onFirstGet(data:XML, fromCache:Boolean):void
            {
                assertNotNull(data);
                assertFalse(fromCache);
                xmlString = data.toXMLString();
                
                HttpManager.getXml(url, null, onSecondGet, onError);
            }
            
            function onSecondGet(data:XML, fromCache:Boolean):void
            {
                assertEqual(xmlString, data.toXMLString());
                assert(fromCache);
                onComplete();
            }
            
            function onError(error:String):void
            {
                fail(error);
                onComplete();
            }
        }
        
        public function testPost(onComplete:Function):void
        {
            var url:String = Constants.createLeaderboardUrl("scores");
            var params:Object = createParams("testPost");
            
            HttpManager.post(url, params, Constants.GAME_KEY, onPostComplete, onError);
            
            function onPostComplete():void
            {
                onComplete();
            }
            
            function onError(error:String):void
            {
                fail(error);
                onComplete();
            }
        }
        
        public function testPostQueue(onComplete:Function):void
        {
            var url:String = Constants.createLeaderboardUrl("scores");
            
            HttpManager.postQueued(url, createParams("testPostQueue"), Constants.GAME_KEY);
            HttpManager.postQueued(url, createParams("testPostQueue"), Constants.GAME_KEY);
            
            assertEqual(2, HttpManager.queueLength);
            var intervalHandle:uint = setInterval(checkQueue, 100);
            var timeoutHandle:uint = setTimeout(abort, 10000);
            
            function checkQueue():void
            {
                if (HttpManager.queueLength == 0)
                {
                    clearInterval(intervalHandle);
                    clearTimeout(timeoutHandle);
                    onComplete();
                }
            }
            
            function abort():void
            {
                clearInterval(intervalHandle);
                clearTimeout(timeoutHandle);
                fail("Queue did not empty");
                onComplete();
            }
        }
        
        private function createParams(playerID:String):Object
        {
            return { 
                "playerId": playerID,
                "playerName": playerID,
                "value": int(Math.random() * 20) 
            };
        }
    }
}
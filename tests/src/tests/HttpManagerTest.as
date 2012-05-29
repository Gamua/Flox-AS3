package tests
{
    import com.gamua.flox.HttpManager;
    
    import flash.utils.describeType;
    
    import starling.unit.UnitTest;
    
    public class HttpManagerTest extends UnitTest
    {
        public function testCache(onComplete:Function):void
        {
            var url:String = "http://www.flox.cc/api/games/unit-test-app/leaderboards/default/scores/allTime.xml";
            var xmlString:String;
            
            HttpManager.clearCache();
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
    }
}
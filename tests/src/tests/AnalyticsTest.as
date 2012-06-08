package tests
{
    import com.gamua.flox.Analytics;
    import com.gamua.flox.HttpManager;
    
    import flash.utils.setTimeout;
    
    import starling.unit.UnitTest;

    public class AnalyticsTest extends UnitTest
    {
        public override function setUp():void
        {
            HttpManager.init(Constants.BASE_URL);
        }
        
        public function testSession(onComplete:Function):void
        {
            // nothing to actually test here, because the analytics class just uploads the 
            // data and can't retrieve it from the server. This test is solely an easy way to
            // step through the code.
            
            Analytics.startSession(Constants.GAME_ID, Constants.GAME_KEY, "0.1");
            
            Analytics.logInfo("This is the first info log");
            Analytics.logWarning("This is a warning log");
            Analytics.logError("This is an error log");
            Analytics.logEvent("AnalyticsTestExecuted");
            Analytics.logInfo("This is the last info log");
            
            setTimeout(endSession, 2000);
            
            function endSession():void
            {
                Analytics.endSession(Constants.GAME_ID, Constants.GAME_KEY);
                onComplete();
            }
        }
    }
}
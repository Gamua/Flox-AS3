package com.gamua.flox
{
    
    import flash.utils.setTimeout;
    
    import starling.unit.UnitTest;

    public class AnalyticsTest extends UnitTest
    {
        public function testSession(onComplete:Function):void
        {
            // nothing to actually test here, because the analytics class just uploads the 
            // data and can't retrieve it from the server. This test is solely an easy way to
            // step through the code.
            
            Flox.init(Constants.GAME_ID, "abc" /* Constants.GAME_KEY */, "1.0");
            
            Flox.logInfo("This is the first info log");
            Flox.logWarning("This is a warning log");
            Flox.logError("This is an error log");
            Flox.logEvent("AnalyticsTestExecuted");
            Flox.logInfo("This is the last info log");
            
            Flox.shutdown();
            
            // start another session - only now will the previous session be transmitted!
            
            Flox.init(Constants.GAME_ID, Constants.GAME_KEY, "1.0");
            Flox.shutdown();
            
            setTimeout(onComplete, 2000);
        }
    }
}
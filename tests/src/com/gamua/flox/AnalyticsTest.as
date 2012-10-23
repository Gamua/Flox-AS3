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
            
            TestHelpers.initFlox();
            
            var numbers:Array = [10, 20, 30];
            var strings:Array = ["hugo", "berti", "sepp"];
            var booleans:Array = [false, true];
            var eventProperties:Object = {
                "number":   numbers[int(Math.random() * numbers.length)],
                "string":   strings[int(Math.random() * strings.length)],
                "boolean":  booleans[int(Math.random() * booleans.length)]
            };
            
            Flox.logInfo("This is the first {0} log", "info");
            Flox.logWarning("This is a {0} log", "warning");
            Flox.logError("Error");
            Flox.logError("AnotherError", "Additional Information");
            Flox.logError("YetAnotherError", "More Info", new Error().getStackTrace());
            Flox.logEvent("AnalyticsTestExecuted");
            Flox.logEvent("EventWithProperties", eventProperties);
            Flox.logEvent("EventWithSingleStringProperty", eventProperties.string);
            Flox.logEvent("EventWithSingleNumberProperty", eventProperties.number);
            Flox.logEvent("EventWithSingleBooleanProperty", eventProperties.boolean);
            Flox.logInfo("This is the last info log");
            
            setTimeout(endSession, 1100);
            
            function endSession():void
            {
                // start another session - only now will the previous session be transmitted!
                TestHelpers.initFlox();
                setTimeout(onComplete, 200);
            }
        }
    }
}
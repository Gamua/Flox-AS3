package
{
    import com.gamua.flox.*;
    
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.unit.TestGui;
    import starling.unit.TestRunner;
    
    public class TestSuite extends Sprite
    {
        public function TestSuite()
        {
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }
        
        private function onAddedToStage(event:Event):void
        {
            var testRunner:TestRunner = new TestRunner();
            
            if (Constants.BASE_URL.indexOf("/api") != Constants.BASE_URL.length - 4)
                throw new Error("You entered an invalid BASE_URL, stupid!");
            
            // --- add tests here ---
            
            // offline tests
            testRunner.add(PersistentStoreTest);
            testRunner.add(PersistentQueueTest);
            testRunner.add(UtilsTest);
            
            // online tests
            testRunner.add(RestServiceTest);
            testRunner.add(AnalyticsTest);
            testRunner.add(ScoreTest);
            
            // ---
            
            var padding:int = 10;
            var width:int   = stage.stageWidth  - 2*padding;
            var height:int  = stage.stageHeight - 2*padding;
            
            var testGui:TestGui = new TestGui(testRunner, width, height);
            testGui.x = testGui.y = padding;
            addChild(testGui);
            
            testGui.start();
        }
    }
}
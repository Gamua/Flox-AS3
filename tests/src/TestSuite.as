package
{
    import com.gamua.flox.AccessTest;
    import com.gamua.flox.AnalyticsTest;
    import com.gamua.flox.Constants;
    import com.gamua.flox.EntityTest;
    import com.gamua.flox.HeroTest;
    import com.gamua.flox.PersistentQueueTest;
    import com.gamua.flox.PersistentStoreTest;
    import com.gamua.flox.PlayerTest;
    import com.gamua.flox.QueryTest;
    import com.gamua.flox.RestServiceTest;
    import com.gamua.flox.ScoreTest;
    import com.gamua.flox.SharedObjectPoolTest;
    import com.gamua.flox.UtilsTest;
    
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
            testRunner.add(SharedObjectPoolTest);
            testRunner.add(PersistentStoreTest);
            testRunner.add(PersistentQueueTest);
            testRunner.add(UtilsTest);
            
            // online tests
            testRunner.add(RestServiceTest);
            testRunner.add(AnalyticsTest);
            testRunner.add(ScoreTest);
            testRunner.add(EntityTest);
            testRunner.add(QueryTest);
            testRunner.add(PlayerTest);
            testRunner.add(AccessTest);
            testRunner.add(HeroTest);
            
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
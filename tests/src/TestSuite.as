package
{
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.unit.TestGui;
    import starling.unit.TestRunner;
    
    import tests.*;
    
    public class TestSuite extends Sprite
    {
        public function TestSuite()
        {
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }
        
        private function onAddedToStage(event:Event):void
        {
            var testRunner:TestRunner = new TestRunner();
            
            testRunner.add(UtilsTest);
            testRunner.add(ScoreTest);
            testRunner.add(LeaderboardTest);
            testRunner.add(HttpManagerTest);
            testRunner.add(AnalyticsTest);
            
            var padding:int = 10;
            var width:int  = stage.stageWidth  - 2*padding;
            var height:int = stage.stageHeight - 2*padding;
            
            var testGui:TestGui = new TestGui(testRunner, width, height);
            testGui.x = testGui.y = padding;
            addChild(testGui);
            
            testGui.start();
        }
    }
}
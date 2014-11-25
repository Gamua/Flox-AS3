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
    import com.gamua.flox.utils.HttpMethod;
    import com.gamua.flox.utils.makeHttpRequest;

    import flash.external.ExternalInterface;

    import starling.core.Starling;
    import starling.display.Sprite;
    import starling.display.Stage;
    import starling.unit.TestGui;
    import starling.unit.TestRunner;

    public class TestSuite extends Sprite
    {
        [Embed(source="../config/live-server.xml", mimeType="application/octet-stream")]
        private static var serverConfig:Class;
        
        public function TestSuite()
        {
            loadConfig(start);
        }
        
        private function start():void
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
            var stage:Stage = Starling.current.stage;
            var width:int   = stage.stageWidth  - 2*padding;
            var height:int  = stage.stageHeight - 2*padding;
            
            var testGui:TestGui = new TestGui(testRunner, width, height);
            testGui.x = testGui.y = padding;
            addChild(testGui);
            
            testGui.log("--> Running on " + Constants.BASE_URL);
            testGui.start();
        }
        
        private function loadConfig(onComplete:Function):void
        {
            var flashVars:Object = Starling.current.nativeStage.loaderInfo.parameters;
            
            if ("config" in flashVars)
            {
                makeHttpRequest(HttpMethod.GET, flashVars["config"], null,
                        onDownloadComplete, onDownloadError);
            }
            else
            {
                Constants.initWithXML(XML(new serverConfig()));
                onComplete();
            }
            
            function onDownloadComplete(config:String):void
            {
                Constants.initWithXML(XML(config));
                onComplete();
            }
            
            function onDownloadError(error:String):void
            {
                if (ExternalInterface.available)
                    ExternalInterface.call("alert", "Could not load config file");
            }
        }
    }
}
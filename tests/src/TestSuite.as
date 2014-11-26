package
{
    import com.gamua.flox.AccessTest;
    import com.gamua.flox.AnalyticsTest;
    import com.gamua.flox.Constants;
    import com.gamua.flox.EntityTest;
    import com.gamua.flox.Flox;
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
    import starling.unit.TestGuiEx;
    import starling.unit.TestGuiFull;
    import starling.unit.TestRunner;

    public class TestSuite extends Sprite
    {
        [Embed(source="../config/live-server.xml", mimeType="application/octet-stream")]
        private static var serverConfig:Class;

        private var _testRunner:TestRunner;
        private var _testGui:TestGui;

        public function TestSuite()
        {
            _testRunner = new TestRunner();

            // offline tests
            _testRunner.add(SharedObjectPoolTest);
            _testRunner.add(PersistentStoreTest);
            _testRunner.add(PersistentQueueTest);
            _testRunner.add(UtilsTest);

            // online tests
            _testRunner.add(RestServiceTest);
            _testRunner.add(AnalyticsTest);
            _testRunner.add(ScoreTest);
            _testRunner.add(EntityTest);
            _testRunner.add(QueryTest);
            _testRunner.add(PlayerTest);
            _testRunner.add(AccessTest);
            _testRunner.add(HeroTest);

            loadConfig(start);
        }
        
        private function start():void
        {
            if (Constants.BASE_URL.indexOf("/api") != Constants.BASE_URL.length - 4)
                throw new Error("You entered an invalid BASE_URL, stupid!");

            _testGui.log("--> Running on " + Constants.BASE_URL);
            _testGui.start();
        }
        
        private function loadConfig(onComplete:Function):void
        {
            var padding:int = 10;
            var stage:Stage = Starling.current.stage;
            var width:int   = stage.stageWidth  - 2*padding;
            var height:int  = stage.stageHeight - 2*padding;
            var flashVars:Object = Starling.current.nativeStage.loaderInfo.parameters;
            
            if ("config" in flashVars)
            {
                _testGui = new TestGuiEx(_testRunner, width, Flox.VERSION);
                makeHttpRequest(HttpMethod.GET, flashVars["config"], null,
                        onDownloadComplete, onDownloadError);
            }
            else
            {
                _testGui = new TestGuiFull(_testRunner, width, height);
                onDownloadComplete(XML(new serverConfig()));
            }

            _testGui.x = _testGui.y = padding;
            addChild(_testGui);

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
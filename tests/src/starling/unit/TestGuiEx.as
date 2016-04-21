package starling.unit
{
    import com.gamua.flox.utils.formatString;

    import flash.external.ExternalInterface;

    import starling.core.Starling;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.text.TextField;
    import starling.utils.Color;

    public class TestGuiEx extends TestGui
    {
        private static const LINE_HEIGHT:int = 20;
        private static const FONT_NAME:String = "mini";
        private static const FONT_SIZE:int = -2;
        
        private var mHeader:TextField;
        private var mStatus:TextField;
        private var mFooter:TextField;

        public function TestGuiEx(testRunner:TestRunner, width:int, header:String)
        {
            super(testRunner);

            mHeader = new TextField(width, LINE_HEIGHT, header);
            mHeader.format.setTo(FONT_NAME, FONT_SIZE, Color.WHITE);
            addChild(mHeader);
            
            mStatus = new TextField(width, LINE_HEIGHT, "0 / 0");
            mStatus.format.setTo(FONT_NAME, FONT_SIZE, Color.WHITE);
            mStatus.y = LINE_HEIGHT;
            addChild(mStatus);
            
            mFooter = new TextField(width, LINE_HEIGHT, "");
            mFooter.format.setTo(FONT_NAME, FONT_SIZE, Color.WHITE);
            mFooter.y = 2 * LINE_HEIGHT;
            addChild(mFooter);
            
            addEventListener(TouchEvent.TOUCH, onTouch);
        }

        override public function onFinished():void
        {
            mFooter.text = "Done";
            callExternalInterface("startNextTest");
        }

        private function onTouch(event:TouchEvent):void
        {
            var touch:Touch = event.getTouch(this, TouchPhase.ENDED);
            if (touch && isStarted)
            {
                isPaused   = !isPaused;
                mFooter.text = isPaused ? "paused" : "";
            }
        }
        
        override public function log(message:String, color:uint=0xffffff):void
        {
            super.log(message, color);
            callExternalInterface("addLog", message, color);
        }
        
        override public function assert(success:Boolean, message:String=null):void
        {
            super.assert(success, message);

            mStatus.text = formatString("{0} / {1}", successCount, testCount);
            mStatus.format.color = (successCount == testCount) ? Color.GREEN : Color.RED;
        }
        
        private function callExternalInterface(method, ...args):void
        {
            if (ExternalInterface.available)
            {
                var url:String = Starling.current.nativeStage.loaderInfo.url;
                var swfName:String = url.split("/").pop().replace(/\?.*$/, "").slice(0, -4);
                args.unshift(method, swfName);
                ExternalInterface.call.apply(null, args);
            }
        }
    }
}

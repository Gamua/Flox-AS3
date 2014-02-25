package starling.unit
{
    import flash.external.ExternalInterface;
    import flash.utils.getTimer;
    
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.text.TextField;
    import starling.utils.Color;
    import starling.utils.formatString;
    
    public class TestGuiEx extends Sprite
    {
        private static const LINE_HEIGHT:int = 20;
        private static const FONT_NAME:String = "mini";
        private static const FONT_SIZE:int = -2;
        
        private var mID:String;
        private var mTestRunner:TestRunner;
        private var mTestCount:int;
        private var mSuccessCount:int;
        private var mHeader:TextField;
        private var mStatus:TextField;
        private var mFooter:TextField;
        private var mStartMoment:Number;
        
        public function TestGuiEx(testRunner:TestRunner, width:int, id:String)
        {
            mID = id;
            
            mTestRunner = testRunner;
            mTestRunner.logFunction    = log;
            mTestRunner.assertFunction = assert;
            
            mHeader = new TextField(width, LINE_HEIGHT, id, FONT_NAME, FONT_SIZE, Color.WHITE);
            addChild(mHeader);
            
            mStatus = new TextField(width, LINE_HEIGHT, "0 / 0", FONT_NAME, FONT_SIZE, Color.WHITE);
            mStatus.y = LINE_HEIGHT;
            addChild(mStatus);
            
            mFooter = new TextField(width, LINE_HEIGHT, "", FONT_NAME, FONT_SIZE, Color.WHITE);
            mFooter.y = 2 * LINE_HEIGHT;
            addChild(mFooter);
            
            addEventListener(TouchEvent.TOUCH, onTouch);
        }
        
        public function start():void
        {
            mTestCount = mSuccessCount = 0;
            mStartMoment = getTimer() / 1000;
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
        
        public function stop():void
        {
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            mTestRunner.resetRun();
            mStartMoment = -1;
        }
        
        private function onEnterFrame(event:Event):void
        {
            var status:String = mTestRunner.runNext();
            
            if (status == TestRunner.STATUS_FINISHED)
            {
                var duration:int = getTimer() / 1000 - mStartMoment;
                stop();
                
                log("Finished all tests!", Color.AQUA);
                log("Duration: " + duration + " seconds.", Color.AQUA);
                
                mFooter.text = "restart";
            }
        }
        
        private function onTouch(event:TouchEvent):void
        {
            var touch:Touch = event.getTouch(this, TouchPhase.ENDED);
            if (touch && !isStarted)
            {
                mFooter.text = "";
                start();
            }
        }
        
        public function log(message:String, color:uint=0xffffff):void
        {
            trace(message);
            
            if (ExternalInterface.available)
                ExternalInterface.call("addLog", mID, message, color);
        }
        
        public function assert(success:Boolean, message:String=null):void
        {
            mTestCount++;
            
            if (success)
            {
                mSuccessCount++;
            }
            else
            {
                message = message ? message : "Assertion failed.";
                log(" " + message, Color.RED);
            }
            
            mStatus.text = formatString("{0} / {1}", mSuccessCount, mTestCount);
            mStatus.color = (mSuccessCount == mTestCount) ? Color.GREEN : Color.RED;
        }
        
        public function get isStarted():Boolean
        {
            return mStartMoment >= 0;
        }
    }
}

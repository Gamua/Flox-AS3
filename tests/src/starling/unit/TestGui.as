package starling.unit
{
    import flash.utils.getTimer;

    import starling.display.Sprite;
    import starling.events.Event;
    import starling.utils.Color;

    public class TestGui extends Sprite
    {
        private var mTestRunner:TestRunner;
        private var mLoop:Boolean;
        private var mTestCount:int;
        private var mSuccessCount:int;
        private var mStartMoment:Number;
        private var mIsPaused:Boolean;

        public function TestGui(testRunner:TestRunner)
        {
            mTestRunner = testRunner;
            mTestRunner.logFunction    = log;
            mTestRunner.assertFunction = assert;
        }

        public function start(loop:Boolean=false):void
        {
            mLoop = loop;
            mStartMoment = getTimer() / 1000;
            mIsPaused = false;
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        public function stop():void
        {
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            mTestRunner.resetRun();
        }

        private function onEnterFrame(event:Event):void
        {
            if (mIsPaused) return;

            var status:String = mTestRunner.runNext();

            if (status == TestRunner.STATUS_FINISHED)
            {
                var duration:int = getTimer() / 1000 - mStartMoment;
                stop();

                log("Finished all tests!", Color.AQUA);
                log("Duration: " + duration + " seconds.", Color.AQUA);

                if (mLoop) start(true);
                else       onFinished();
            }
        }

        public function onFinished():void
        {
            // override in subclass
        }

        public function log(message:String, color:uint=0xffffff):void
        {
            trace(message);
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
        }

        public function get testCount():int { return mTestCount; }
        public function get successCount():int { return mSuccessCount; }
        public function get isStarted():Boolean { return mStartMoment >= 0; }

        public function get isPaused():Boolean { return mIsPaused; }
        public function set isPaused(value:Boolean):void { mIsPaused = value; }
    }
}
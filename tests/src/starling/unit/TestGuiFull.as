package starling.unit
{
    import com.gamua.flox.utils.formatString;

    import starling.display.Sprite;
    import starling.text.TextField;
    import starling.utils.Align;
    import starling.utils.Color;

    public class TestGuiFull extends TestGui
    {
        private static const LINE_HEIGHT:int = 10;
        private static const FONT_NAME:String = "mini";
        private static const FONT_SIZE:int = -1;
        
        private var mWidth:int;
        private var mHeight:int;
        private var mLogLines:Sprite;
        private var mNumLogLines:int;
        private var mStatusInfo:TextField;

        public function TestGuiFull(testRunner:TestRunner, width:int, height:int)
        {
            super(testRunner);

            mWidth = width;
            mHeight = height;
            
            mStatusInfo = new TextField(width, LINE_HEIGHT, "");
            mStatusInfo.format.setTo(FONT_NAME, FONT_SIZE, Color.WHITE);
            mStatusInfo.format.horizontalAlign = Align.RIGHT;
            addChild(mStatusInfo);
            
            mLogLines = new Sprite();
            addChild(mLogLines);
        }
        
        override public function log(message:String, color:uint=0xffffff):void
        {
            super.log(message, color);

            var logLine:TextField = new TextField(mWidth, LINE_HEIGHT, message);
            logLine.format.setTo(FONT_NAME, FONT_SIZE, color);
            logLine.format.horizontalAlign = Align.LEFT;
            logLine.y = mNumLogLines * LINE_HEIGHT;
            mLogLines.addChild(logLine);
            mNumLogLines++;
            
            if (mNumLogLines * LINE_HEIGHT > mHeight)
            {
                mLogLines.removeChildAt(0);
                mLogLines.y -= LINE_HEIGHT;
            }
        }
        
        override public function assert(success:Boolean, message:String=null):void
        {
            super.assert(success, message);
            
            mStatusInfo.text = formatString("Passed {0} of {1} tests", successCount, testCount);
            mStatusInfo.format.color = (successCount == testCount) ? Color.GREEN : Color.RED;
        }
    }
}
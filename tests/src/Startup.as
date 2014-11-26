package
{
    import com.gamua.flox.Flox;

    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.UncaughtErrorEvent;

    import starling.core.Starling;

    [SWF(width="800", height="600", frameRate="30", backgroundColor="#000000")]
    public class Startup extends Sprite
    {
        private var mStarling:Starling;

        public function Startup()
        {
            loaderInfo.uncaughtErrorEvents.addEventListener (
                UncaughtErrorEvent.UNCAUGHT_ERROR, function(event:UncaughtErrorEvent):void
                {
                    Flox.logError(event.error, "Uncaught Error: " + event.error.message);
                }
            );

            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;

            mStarling = new Starling(TestSuite, stage);
            mStarling.start();
        }
    }
}
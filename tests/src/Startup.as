package
{
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    
    import starling.core.Starling;
    import starling.unit.TestRunner;
    
    [SWF(width="400", height="600", frameRate="20", backgroundColor="#000000")]
    public class Startup extends Sprite
    {
        private var mStarling:Starling;
        
        public function Startup()
        {
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            
            mStarling = new Starling(FloxTest, stage);
            mStarling.start();
        }
    }
}
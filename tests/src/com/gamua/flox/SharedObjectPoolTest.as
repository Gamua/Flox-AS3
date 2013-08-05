package com.gamua.flox
{
    import com.gamua.flox.utils.setTimeout;
    
    import flash.net.SharedObject;
    
    import starling.unit.UnitTest;
    
    public class SharedObjectPoolTest extends UnitTest
    {
        private static const NAME:String = "test";
        
        public function testAccess(onComplete:Function):void
        {
            var interval:Number = 0.2;
            
            SharedObjectPool.startAutoCleanup(interval);
            
            var so1:SharedObject = SharedObjectPool.getObject(NAME);
            so1.data.value = "value";
            
            var so2:SharedObject = SharedObjectPool.getObject(NAME);
            
            assertEqual(so1, so2);
            assertEqual(so1.data.value, so2.data.value);
            
            setTimeout(afterFirstCleanup,  300);
            setTimeout(afterSecondCleanup, 500);
            setTimeout(afterThirdCleanup,  700, onComplete);
        }
        
        private function afterFirstCleanup():void
        {
            assert(SharedObjectPool.contains(NAME));
            var restored:SharedObject = SharedObjectPool.getObject(NAME);
        }
        
        private function afterSecondCleanup():void
        {
            assert(SharedObjectPool.contains(NAME));
        }
        
        private function afterThirdCleanup(onComplete:Function):void
        {
            assert(!SharedObjectPool.contains(NAME));
            onComplete();
        }
    }
}
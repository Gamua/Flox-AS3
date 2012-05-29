package starling.unit
{
    public class UnitTest
    {        
        private var mAssertFunction:Function;
        
        public function UnitTest()
        { }
        
        public function setUp():void
        { }
        
        public function tearDown():void
        { }
        
        protected function assert(condition:Boolean, message:String=null):void
        {
            if (mAssertFunction != null) 
                mAssertFunction(condition, message);
        }
        
        protected function assertFalse(condition:Boolean, message:String=null):void
        {
            assert(!condition, message);
        }
        
        protected function assertEqual(objectA:Object, objectB:Object, message:String=null):void
        {
            assert(objectA == objectB, message);
        }
        
        protected function assertEquivalent(numberA:Number, numberB:Number, 
                                            message:String=null, e:Number=0.0001):void
        {
            assert(numberA - e < numberB && numberA + e > numberB, message);
        }
        
        protected function assertNull(object:Object, message:String=null):void
        {
            assert(object == null, message);
        }
        
        protected function assertNotNull(object:Object, message:String=null):void
        {
            assert(object != null, message);
        }
        
        protected function fail(message:String):void
        {
            assert(false, message);
        }
        
        protected function succeed(message:String):void
        {
            assert(true, message);
        }
        
        internal function get assertFunction():Function { return mAssertFunction; }
        internal function set assertFunction(value:Function):void { mAssertFunction = value; }
    }
}
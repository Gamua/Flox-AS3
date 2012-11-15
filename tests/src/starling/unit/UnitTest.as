package starling.unit
{
    import flash.utils.describeType;
    import flash.utils.getQualifiedClassName;

    public class UnitTest
    {        
        private var mAssertFunction:Function;
        
        public function UnitTest()
        { }
        
        public function setUp():void
        { }
        
        public function setUpAsync(onComplete:Function):void
        {
            onComplete();
        }
        
        public function tearDown():void
        { }
        
        public function tearDownAsync(onComplete:Function):void
        {
            onComplete();
        }
        
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
        
        protected function assertEqualObjects(objectA:Object, objectB:Object, message:String=null):void
        {
            assert(compareObjects(objectA, objectB), message);
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
        
        // helpers
        
        private function compareObjects(objectA:Object, objectB:Object):Boolean
        {
            if (objectA is int || objectA is uint || objectA is Number || objectA is Boolean)
                return objectA === objectB;
            else if (objectA is Date && objectB is Date)
                return objectA.time - 500 < objectB.time && objectA.time + 500 > objectB.time;
            else
            {
                var nameA:String = getQualifiedClassName(objectA);
                var nameB:String = getQualifiedClassName(objectB);
                var prop:String;
                
                if (nameA != nameB) return false;
                
                if (objectA is Array || nameA.indexOf("__AS3__.vec::Vector.") == 0)
                {
                    if (objectA.length != objectB.length) return false;
                    
                    for (var i:int=0; i<objectA.length; ++i)
                        if (!compareObjects(objectA[i], objectB[i])) return false;
                }
                
                // we can iterate like this through 'Object', 'Array' and 'Vector' 
                for (prop in objectA)
                {
                    if (!objectB.hasOwnProperty(prop)) return false;
                    else if (!compareObjects(objectA[prop], objectB[prop])) return false;
                }
                
                // other classes need to be iterated through with the type description
                var typeDescription:XML = describeType(objectA);
                for each (var accessor:XML in typeDescription.accessor)
                {
                    prop = accessor.@name.toString();                
                    if (!compareObjects(objectA[prop], objectB[prop])) return false;
                }
                
                return true;
            }
        }
    }
}
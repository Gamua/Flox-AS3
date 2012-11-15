package com.gamua.flox
{
    import starling.unit.UnitTest;
    
    public class PersistentStoreTest extends UnitTest
    {
        private static const STORE_NAME:String = "store-name";
        
        public override function setUp():void
        {
            (new PersistentStore(STORE_NAME)).clear();
        }
        
        public function testSetGetClear():void
        {
            var store:PersistentStore = new PersistentStore(STORE_NAME);
            
            var object0:Object = { "string": "hugo", "number": 0 };
            var object1:Object = { "string": "tina", "number": 1 };
            var object2:Object = { "string": "anna", "number": 2 };
            
            store.setObject("nil!", object0); // use a few special chars to make sure 
            store.setObject("one/", object1); // that's allowed
            store.setObject("two:", object2);
            
            assert(store.containsKey("nil!"));
            assert(store.containsKey("one/"));
            assert(store.containsKey("two:"));
            
            assertEqualObjects(store.getObject("nil!"), object0);
            assertEqualObjects(store.getObject("one/"), object1);
            assertEqualObjects(store.getObject("two:"), object2);
                
            store.removeObject("one/");
            
            assert(store.containsKey("nil!"));
            assertFalse(store.containsKey("one/"));
            assert(store.containsKey("two:"));
            
            store.clear();
            
            assertFalse(store.containsKey("nil!"));
            assertFalse(store.containsKey("two:"));
        }
        
        public function testPersistency():void
        {
            var store:PersistentStore = new PersistentStore(STORE_NAME);
            
            var object0:Object = { "string": "hugo", "number": 0 };
            var object1:Object = { "string": "tina", "number": 1 };
            
            store.setObject("nil&", object0);
            store.setObject("one(", object1);
            
            store = new PersistentStore(STORE_NAME);
            
            assertEqualObjects(store.getObject("nil&"), object0);
            assertEqualObjects(store.getObject("one("), object1);
        }
        
        public function testMetaData():void
        {
            var store:PersistentStore = new PersistentStore(STORE_NAME);
            
            store.setObject("one", "ONE");
            store.setObject("two", "TWO");
            
            store.setMetaData("one", "value", 1);
            store.setMetaData("two", "value", 2);
            
            assertEqual(1, store.getMetaData("one", "value"));
            assertEqual(2, store.getMetaData("two", "value"));
            
            // persistency
            
            store = new PersistentStore(STORE_NAME);
            
            assertEqual(1, store.getMetaData("one", "value"));
            assertEqual(2, store.getMetaData("two", "value"));
        }
    }
}
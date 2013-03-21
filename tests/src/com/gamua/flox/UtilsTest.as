package com.gamua.flox
{
    import com.gamua.flox.utils.DateUtil;
    import com.gamua.flox.utils.cloneObject;
    import com.gamua.flox.utils.createUID;
    import com.gamua.flox.utils.createURL;
    
    import starling.unit.UnitTest;
    
    public class UtilsTest extends UnitTest
    {
        public function testCreateUrl():void
        {
            assertEqual("http://www.gamua.com/test", createURL("http://www.gamua.com/", "/test"));
            assertEqual("http://www.gamua.com/test", createURL("http://www.gamua.com", "test"));
            assertEqual("a/b/c", createURL("a/", "/b/", "/c"));
            
            // empty string
            assertEqual("a/b", createURL("a", "", "b"));
            
            // null string
            assertEqual("a/b", createURL("a", null, "b"));
            
            // slash at start and/or end must remain
            assertEqual("/a/b/c/", createURL("/a/", "/b/", "/c/"));
        }
        
        public function testDateToString():void
        {
            var ms:Number = Date.UTC(2012, 8, 3, 14, 36, 2, 9);
            var date:Date = new Date(ms);
            assertEqual("2012-09-03T14:36:02.009Z", DateUtil.toString(date));
            
            date.milliseconds = 88;
            assertEqual("2012-09-03T14:36:02.088Z", DateUtil.toString(date));
            
            date.milliseconds = 123;
            assertEqual("2012-09-03T14:36:02.123Z", DateUtil.toString(date));
        }
        
        public function testCloneObject():void
        {
            var object:Object = {
                "integer": 15,
                "number": 1.5,
                "boolean": true,
                "complex": { "one": 1, "two": { value: 2 } },
                "array": [ "hugo", false, { dunno: [1, 2, 3] } ]
            };
            
            var clone:Object = cloneObject(object);
            
            assert(object != clone);
            assertEqualObjects(object, clone);
            
            var integer:int = 15;
            var integerClone:Object = cloneObject(integer);
            
            assertEqual(integer, integerClone);
        }
        
        public function testCloneObjectWithFilter():void
        {
            var date:Date = new Date(2013, 1, 1);
            var object:Object = {
                "integer": 15,
                "number": 1.5,
                "date": date
            };
            
            var clone:Object = cloneObject(object, function(object:*):*
            {
                if (object is Date) return DateUtil.toString(object as Date);
                else return null;
            });
            
            assertEqual(DateUtil.toString(date), clone.date);
        }
        
        public function testCreateUID():void
        {
            var uid:String = createUID();
            assertEqual(22, uid.length, "UID does not have the right length");
        }
    }
}
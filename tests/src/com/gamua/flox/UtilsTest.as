package com.gamua.flox
{
    import com.gamua.flox.utils.DateUtil;
    import com.gamua.flox.utils.SHA256;
    import com.gamua.flox.utils.cloneObject;
    import com.gamua.flox.utils.createUID;
    import com.gamua.flox.utils.createURL;
    import com.gamua.flox.utils.setTimeout;
    
    import flash.utils.getTimer;
    
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
        
        public function testCloneObjectWithNonSerializedMetaData():void
        {
            var object:CustomObject = new CustomObject();
            object.publicVar = 1;
            object.publicNonSerializedMember = 2;
            object.publicNonSerializedProperty = 3;
            
            var clone:Object = cloneObject(object);
            
            assertEqual(clone.publicVar, object.publicVar);
            assertFalse("publicNonSerializedMember" in clone);
            assertFalse("publicNonSerializedProperty" in clone);
        }
        
        public function testCreateUID():void
        {
            var length:int;
            var uid:String;
            var seed:String;
            
            for (length=0; length<43; ++length)
            {
                uid = createUID(length);
                assertEqual(length, uid.length, "UID does not have the right length");
            }
            
            for (length=0; length<43; ++length)
            {
                seed = Math.random().toString();
                uid = createUID(length, seed);
                assertEqual(length, uid.length, "UID does not have the right length");
                assertEqual(uid, createUID(length, seed), "UIDs with identical seeds differ");
            }
        }
        
        public function testSetTimeout(onComplete:Function):void
        {
            var startMoment:int = getTimer();
            setTimeout(onTimeout, 500, 1, "two", 3);
            
            function onTimeout(a:int, b:String, c:int):void
            {
                var endMoment:int = getTimer();
                assertEquivalent(endMoment - startMoment, 500, "wrong timeout duration", 100);
                assertEqual(1, a);
                assertEqual("two", b);
                assertEqual(3, c);
                onComplete();
            }
        }
        
        public function testSHA256():void
        {
            var string1:String = "Victor";
            var string2:String = "Victory";
            
            var sha1:String  = SHA256.hashString(string1);
            var sha2:String  = SHA256.hashString(string2);
            var sha1b:String = SHA256.hashString(string1);
            var sha2b:String = SHA256.hashString(string2);
            
            assertEqual(sha1, "bADm/26mvMasEi7DFOsWdJyojwN2Ct+3Gp3mV1J8Y5Z=", "wrong SHA");
            assertEqual(sha2, "LptaDE5q6wiRzCyONGv51Va9VZAydEG/2ij982/020P=", "wrong SHA");
            
            assertEqual(sha1, sha1b, "SHA produced different results from the same String");
            assertEqual(sha2, sha2b, "SHA produced different results from the same String");
        }
    }
}

class CustomObject
{
    private var privateVar:int;
    public var publicVar:int;
 
    [NonSerialized]
    public var publicNonSerializedMember:int;
    
    [NonSerialized]
    public function get publicNonSerializedProperty():int { return privateVar; }
    public function set publicNonSerializedProperty(value:int):void { privateVar = value; }
    
    public function CustomObject()
    {
        privateVar = publicVar = publicNonSerializedMember = 0;
    }
}
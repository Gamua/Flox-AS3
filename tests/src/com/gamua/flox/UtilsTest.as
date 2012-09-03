package com.gamua.flox
{
    import com.gamua.flox.utils.DateUtil;
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
    }
}
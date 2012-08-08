package com.gamua.flox
{
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
    }
}
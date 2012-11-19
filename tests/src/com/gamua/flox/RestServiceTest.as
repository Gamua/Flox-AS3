package com.gamua.flox
{
    import com.gamua.flox.utils.HttpMethod;
    
    import starling.unit.UnitTest;

    public class RestServiceTest extends UnitTest
    {
        public override function setUp():void
        {
            Constants.initFlox();
        }
        
        public override function tearDown():void
        {
            Flox.shutdown();
        }
        
        public function testGetStatus(onComplete:Function):void
        {
            Flox.service.request(HttpMethod.GET, "", null, onRequestComplete, onRequestError);
            
            function onRequestComplete(body:Object, eTag:String, httpStatus:int):void
            {
                assertEqual(body.status, "ok");
                onComplete();
            }
            
            function onRequestError(error:String, body:Object, eTag:String, httpStatus:int):void
            {
                fail("Could not get server status: " + error);
                onComplete();
            }
        }
        
        public function testProvokeError(onComplete:Function):void
        {
            Flox.service.request(HttpMethod.GET, ".analytics", null, onRequestComplete, onRequestError);

            function onRequestComplete(body:Object, eTag:String, httpStatus:int):void
            {
                fail("Server should have returned error");
                onComplete();
            }
            
            function onRequestError(error:String, body:Object, eTag:String, httpStatus:int):void
            {
                onComplete();
            }
        }
        
        public function testNonExistingMethod(onComplete:Function):void
        {
            Flox.service.request(HttpMethod.GET, ".does-not-exist", null, 
                                 onRequestComplete, onRequestError);
            
            function onRequestComplete(body:Object, eTag:String, httpStatus:int):void
            {
                fail("Server should have returned error");
                onComplete();
            }
            
            function onRequestError(error:String, body:Object, eTag:String, httpStatus:int):void
            {
                onComplete();
            }
        }
    }
}
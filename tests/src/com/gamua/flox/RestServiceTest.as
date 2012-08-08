package com.gamua.flox
{
    import com.gamua.flox.utils.HttpMethod;
    
    import starling.unit.UnitTest;

    public class RestServiceTest extends UnitTest
    {
        public function testGetStatus(onComplete:Function):void
        {
            var restService:RestService = new RestService(Constants.BASE_URL, null, null);
            restService.request(HttpMethod.GET, "", null, null, onRequestComplete, onRequestError);
            
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
            var restService:RestService = new RestService(Constants.BASE_URL, "illegal", null);
            restService.request(HttpMethod.GET, ".analytics", null, null, onRequestComplete, onRequestError);

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
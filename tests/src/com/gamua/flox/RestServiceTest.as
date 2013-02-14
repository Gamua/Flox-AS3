package com.gamua.flox
{
    import com.gamua.flox.events.QueueEvent;
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
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                assertNotNull(body);
                assertEqual(body.status, "ok");
                onComplete();
            }
            
            function onRequestError(error:String, httpStatus:int):void
            {
                fail("Could not get server status: " + error);
                onComplete();
            }
        }

        // not yet supported by Flox Server
        // public function testNonExistingMethod(onComplete:Function):void
        // {
        //     requestNonExistingPath(".does-no-exist", onComplete);
        // }
        
        public function testGetNonExistingEntity(onComplete:Function):void
        {
            requestNonExistingPath("entities/.player/.does-not-exist", onComplete);
        }
        
        private function requestNonExistingPath(path:String, onComplete:Function):void
        {
            Flox.service.request(HttpMethod.GET, path, null, onRequestComplete, onRequestError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                fail("Server should have returned error");
                onComplete();
            }
            
            function onRequestError(error:String, httpStatus:int):void
            {
                onComplete();
            }
        }
        
        public function testQueueEvent(onComplete:Function):void
        {
            Flox.addEventListener(QueueEvent.QUEUE_PROCESSED, onQueueProcessed);
            Flox.service.requestQueued(HttpMethod.GET, "");
            
            function onQueueProcessed(event:Object):void
            {
                Flox.removeEventListener(QueueEvent.QUEUE_PROCESSED, onQueueProcessed);
                onComplete();
            }
        }
    }
}
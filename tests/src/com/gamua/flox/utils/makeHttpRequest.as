package com.gamua.flox.utils
{
    import flash.events.Event;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLVariables;

    public function makeHttpRequest(method:String, url:String, data:URLVariables,
                                    onComplete:Function, onError:Function):void
    {
        var httpStatus:int = -1;
        var loader:URLLoader = new URLLoader();
        loader.addEventListener(Event.COMPLETE, onLoaderComplete);
        loader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
        loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onLoaderHttpStatus);

        var request:URLRequest = new URLRequest(url);
        request.data = data;
        request.method = method;

        loader.load(request);

        function onLoaderComplete(event:Event):void
        {
            closeLoader();
            execute(onComplete, loader.data as String);
        }

        function onLoaderError(event:IOErrorEvent):void
        {
            closeLoader();
            execute(onError, event.text,  httpStatus);
        }

        function onLoaderHttpStatus(event:HTTPStatusEvent):void
        {
            httpStatus = event.status;
        }

        function closeLoader():void
        {
            loader.removeEventListener(Event.COMPLETE, onLoaderComplete);
            loader.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
            loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onLoaderHttpStatus);
            loader.close();
        }

        function encodeForUri(object:Object):String
        {
            var urlVariables:URLVariables = new URLVariables();
            for (var key:String in object) urlVariables[key] = object[key];
            return urlVariables.toString();
        }
    }
}
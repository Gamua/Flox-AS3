// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.utils.DateUtil;
    import com.gamua.flox.utils.createURL;
    import com.gamua.flox.utils.execute;
    import com.hurlant.util.Base64;
    
    import flash.events.Event;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.utils.ByteArray;

    internal class RestService implements IRestService
    {
        private var mUrl:String;
        private var mGameID:String;
        private var mGameKey:String;
        private var mQueue:PersistentQueue;
        private var mProcessingQueue:Boolean;
        
        public function RestService(url:String, gameID:String, gameKey:String)
        {
            mUrl = url;
            mGameID = gameID;
            mGameKey = gameKey;
            mQueue = new PersistentQueue("Flox.RestService.queue." + gameID);
        }
        
        // onComplete(body:Object, eTag:String, httpStatus:int):void
        // onError(error:String, eTag:String, httpStatus:int):void
        public function request(method:String, path:String, data:Object, headers:Object,
                                onComplete:Function, onError:Function):void
        {
            if (headers == null) headers = {};
            
            var xFloxHeader:Object = {
                sdk: { type: "as3", version: Flox.VERSION },
                gameKey: mGameKey,
                bodyCompression: "zlib",
                dispatchTime: DateUtil.toString(new Date())
            };
            
            headers["Content-Type"] = "application/json";
            headers["X-Flox"] = xFloxHeader;
            
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onLoaderComplete);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
            loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onLoaderHttpStatus);

            var httpStatus:int = -1;
            var url:String = createURL("/api", (mGameID ? "games/" + mGameID : ""), path);
            var request:URLRequest = new URLRequest(mUrl);
            request.method = URLRequestMethod.POST;
            request.data = JSON.stringify({
                method: method,
                url: url,
                headers: headers,
                body: encode(data)
            }, null, 2);
            
            loader.load(request);
            
            function onLoaderComplete(event:Event):void
            {
                loader.close();
                
                var response:Object = JSON.parse(loader.data);
                var status:int = parseInt(response.status);
                var headers:Object = response.headers;
                var body:Object = decode(response.body);
                
                if (httpStatus != 200)
                {
                    execute(onError, "Flox Server unreachable", null, httpStatus);
                }
                else
                {
                    if (status < 400)    // success =)
                        execute(onComplete, body, headers.ETag, status);
                    else                 // error =(
                        execute(onError, body.message, headers.ETag, status);
                }
            }
            
            function onLoaderError(event:IOErrorEvent):void
            {
                loader.close();
                execute(onError, "Flox Service IO Error: " + event.text, null, httpStatus);
            }
            
            function onLoaderHttpStatus(event:HTTPStatusEvent):void
            {
                httpStatus = event.status;
            }
        }
        
        public function requestQueued(method:String, path:String, data:Object=null, 
                                      headers:Object=null):void
        {
            mQueue.enqueue({ method: method, path: path, data: data, headers: headers });
            processQueue();
        }
        
        // returns true if queue is currently processing requests
        public function processQueue():Boolean
        {
            if (!mProcessingQueue)
            {
                if (mQueue.length > 0)
                {
                    mProcessingQueue = true;
                    var element:Object = mQueue.peek();
                    request(element.method, element.path, element.data, element.headers,
                            onRequestComplete, onRequestError);
                }
                else mProcessingQueue = false;
            }
            
            return mProcessingQueue;
            
            function onRequestComplete(body:Object, eTag:String, httpStatus:int):void
            {
                mProcessingQueue = false;
                mQueue.dequeue();
                processQueue();
            }
            
            function onRequestError(error:String, eTag:String, httpStatus:int):void
            {
                mProcessingQueue = false;
                
                if (httpStatus == 0 || httpStatus == 503)
                {
                    // server did not answer or is not available! we stop queue processing.
                    Flox.logWarning("Flox Server not available. HttpStatus: {0}", httpStatus);
                }
                else
                {
                    // server answered, but there was a logic error -> no retry
                    Flox.logWarning("Service Queue request failed: {0}", error);
                    
                    mQueue.dequeue();
                    processQueue();
                }
            }
        }
        
        public function save():void
        {
            mQueue.flush();
        }
        
        // object encoding
        
        /** Encodes an object in JSON format, compresses it and returns its Base64 representation. */
        private static function encode(object:Object):String
        {
            // TODO: save memory by truncating the byte array before returning
            
            var data:ByteArray = new ByteArray();
            data.writeUTFBytes(JSON.stringify(object, null, 0));
            data.compress();
            return Base64.encodeByteArray(data);
        }
        
        /** Decodes an object from JSON format, compressed in a Base64-encoded, zlib-compressed String. */ 
        private static function decode(string:String):Object
        {
            if (string == null) return null;
            var data:ByteArray = Base64.decodeToByteArray(string);
            data.uncompress();
            return JSON.parse(data.readUTFBytes(data.length));
        }
    }
}
// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.utils.Base64;
    import com.gamua.flox.utils.DateUtil;
    import com.gamua.flox.utils.createURL;
    import com.gamua.flox.utils.execute;
    
    import flash.events.Event;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.utils.ByteArray;

    /** A class that makes it easy to communicate with the Flox server via a REST protocol. */
    internal class RestService
    {
        private var mUrl:String;
        private var mGameID:String;
        private var mGameKey:String;
        private var mQueue:PersistentQueue;
        private var mProcessingQueue:Boolean;
        private var mAuthentication:Authentication;
        
        /** Create an instance with the base URL of the Flox service. The class will allow 
         *  communication with the entities of a certain game (identified by id and key). */
        public function RestService(url:String, gameID:String, gameKey:String)
        {
            mUrl = url;
            mGameID = gameID;
            mGameKey = gameKey;
            mQueue = new PersistentQueue("Flox.RestService.queue." + gameID);
            mAuthentication = new Authentication("none");
        }
        
        /** Makes an asynchronous HTTP request at the server, with custom authentication data. */
        private function requestWithAuthentication(method:String, path:String, data:Object, 
                                                   headers:Object, authentication:Authentication,
                                                   onComplete:Function, onError:Function):void
        {
            if (headers == null) headers = {};
            
            var xFloxHeader:Object = {
                sdk: { 
                    type: "as3", 
                    version: Flox.VERSION
                },
                player: {  // currently ignored -> see below 
                    id:        authentication.playerID,
                    authType:  authentication.type,
                    authId:    authentication.id,
                    authToken: authentication.token
                },
                playerID: authentication.playerID, // TODO: remove this when server updated
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
                closeLoader();
                
                if (httpStatus != 200)
                {
                    execute(onError, "Flox Server unreachable", null, httpStatus);
                }
                else
                {
                    try
                    {
                        var response:Object = JSON.parse(loader.data);
                        var status:int = parseInt(response.status);
                        var headers:Object = response.headers;
                        var body:Object = decode(response.body);
                    }
                    catch (e:Error)
                    {
                        execute(onError, "Invalid response from Flox server: " + e.message,
                                null, httpStatus);
                        return;
                    }
                    
                    if (status < 400)    // success =)
                        execute(onComplete, body, headers.ETag, status);
                    else                 // error =(
                        execute(onError, body.message, headers.ETag, status);
                }
            }
            
            function onLoaderError(event:IOErrorEvent):void
            {
                closeLoader();
                execute(onError, "Flox Service IO Error: " + event.text, null, httpStatus);
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
        }
        
        /** Makes an asynchronous HTTP request at the server. The method will always execute
         *  exactly one of the provided callback functions.
         *  
         *  @param method: one of the methods provided by the 'HttpMethod' class.
         *  @param path: the path of the resource relative to the root of the game (!).
         *  @param data: the data that will be sent as JSON-encoded body.
         *  @param headers: the data that will be sent as HTTP headers.
         *  @param onComplete: a callback with the form: 
         *                     <pre>onComplete(body:Object, eTag:String, httpStatus:int):void;</pre>
         *  @param onError:    a callback with the form:
         *                     <pre>onError(error:String, eTag:String, httpStatus:int):void;</pre>
         */
        public function request(method:String, path:String, data:Object, headers:Object, 
                                onComplete:Function, onError:Function):void
        {
            requestWithAuthentication(method, path, data, headers, mAuthentication,
                                      onComplete, onError);
        }
        
        /** Adds an asynchronous HTTP request to a queue and immediately starts to process the
         *  queue. */
        public function requestQueued(method:String, path:String, data:Object=null, 
                                      headers:Object=null):void
        {
            mQueue.enqueue({ method: method, path: path, data: data, headers: headers,
                             authentication: mAuthentication });
            processQueue();
        }
        
        /** Processes the request queue, executing requests in the order they were recorded.
         *  If the server cannot be reached, processing stops and is retried later; if a request
         *  produces an error, it is discarded. 
         *  @returns true if the queue is currently being processed. */
        public function processQueue():Boolean
        {
            if (!mProcessingQueue)
            {
                if (mQueue.length > 0)
                {
                    mProcessingQueue = true;
                    var element:Object = mQueue.peek();
                    requestWithAuthentication(element.method, element.path, element.data, 
                        element.headers, element.authentication, onRequestComplete, onRequestError);
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
                    Flox.logInfo("Flox Server not reachable (device probably offline). " + 
                                 "HttpStatus: {0}", httpStatus);
                }
                else
                {
                    // server answered, but there was a logic error -> no retry
                    Flox.logWarning("Flox service queue request failed: {0}", error);
                    
                    mQueue.dequeue();
                    processQueue();
                }
            }
        }
        
        /** Saves the request queue to the disk. */
        public function save():void
        {
            mQueue.flush();
        }
        
        public function get authentication():Authentication { return mAuthentication; }
        public function set authentication(value:Authentication):void { mAuthentication = value; }
        
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
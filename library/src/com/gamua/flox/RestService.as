// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.events.QueueEvent;
    import com.gamua.flox.utils.Base64;
    import com.gamua.flox.utils.DateUtil;
    import com.gamua.flox.utils.HttpMethod;
    import com.gamua.flox.utils.HttpStatus;
    import com.gamua.flox.utils.createURL;
    import com.gamua.flox.utils.execute;
    
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.utils.ByteArray;

    /** A class that makes it easy to communicate with the Flox server via a REST protocol. */
    internal class RestService extends EventDispatcher
    {
        private var mUrl:String;
        private var mGameID:String;
        private var mGameKey:String;
        private var mQueue:PersistentQueue;
        private var mCache:PersistentStore;
        private var mAlwaysFail:Boolean;
        private var mProcessingQueue:Boolean;
        
        /** Helper objects */
        private static var sBuffer:ByteArray = new ByteArray();
        
        /** Create an instance with the base URL of the Flox service. The class will allow 
         *  communication with the entities of a certain game (identified by id and key). */
        public function RestService(url:String, gameID:String, gameKey:String)
        {
            mUrl = url;
            mGameID = gameID;
            mGameKey = gameKey;
            mAlwaysFail = false;
            mProcessingQueue = false;
            mQueue = new PersistentQueue("Flox.RestService.queue." + gameID);
            mCache = new PersistentStore("Flox.RestService.cache." + gameID);
        }
        
        /** Makes an asynchronous HTTP request at the server, with custom authentication data. */
        private function requestWithAuthentication(method:String, path:String, data:Object, 
                                                   authentication:Authentication,
                                                   onComplete:Function, onError:Function):void
        {
            if (method == HttpMethod.GET && data)
            {
                path += "?" + encodeForUri(data);
                data = null;
            }
            
            if (authentication == null)
                authentication = Flox.authentication;
            
            var cachedResult:Object = null;
            var headers:Object = {};
            var xFloxHeader:Object = {
                sdk: { 
                    type: "as3", 
                    version: Flox.VERSION
                },
                player: { 
                    id:        authentication.playerId,
                    authType:  authentication.type,
                    authId:    authentication.id,
                    authToken: authentication.token
                },
                gameKey: mGameKey,
                bodyCompression: "zlib",
                dispatchTime: DateUtil.toString(new Date())
            };
            
            headers["Content-Type"] = "application/json";
            headers["X-Flox"] = xFloxHeader;
            
            if (method == HttpMethod.GET && mCache.containsKey(path))
            {
                cachedResult = mCache.getObject(path);
                if (cachedResult) headers["If-None-Match"] = mCache.getMetaData(path, "eTag");
            }
            
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onLoaderComplete);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
            loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onLoaderHttpStatus);
            
            var httpStatus:int = -1;
            var url:String = createURL("/api", (mGameID ? "games/" + mGameID : ""), path);
            var wrapperUrl:String = mAlwaysFail ? "https://www.invalid-flox.com/api" : mUrl;
            var request:URLRequest = new URLRequest(wrapperUrl);
            var requestData:Object = { 
                method: method, url: url, headers: headers, body: encode(data) 
            };
            
            request.method = URLRequestMethod.POST;
            request.data = JSON.stringify(requestData);
            
            loader.load(request);
            
            function onLoaderComplete(event:Event):void
            {
                closeLoader();
                
                if (httpStatus != HttpStatus.OK)
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
                    
                    if (status < 400) // success =)
                    {
                        var result:Object = body;
                        
                        if (method == HttpMethod.GET)
                        {
                            if (status == HttpStatus.NOT_MODIFIED)
                                result = cachedResult;
                            else
                                mCache.setObject(path, body, { eTag: headers.ETag });
                        }
                        else if (method == HttpMethod.PUT)
                        {
                            mCache.setObject(path, data, { eTag: headers.ETag });
                        }
                        else if (method == HttpMethod.DELETE)
                        {
                            mCache.removeObject(path);
                        }
                        
                        execute(onComplete, result, status);
                    }
                    else // error =(
                    {
                        var error:String = (body && body.message) ? body.message : "unknown";
                        var cachedBody:Object = (method == HttpMethod.GET) ? 
                            mCache.getObject(path) : null;
                        
                        execute(onError, error, status, cachedBody);
                    }
                }
            }
            
            function onLoaderError(event:IOErrorEvent):void
            {
                closeLoader();
                execute(onError, event.text, httpStatus,
                    (method == HttpMethod.GET) ? mCache.getObject(path) : null);
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
        
        /** Makes an asynchronous HTTP request at the server. Before doing that, it will always
         *  process the request queue. If that fails with a non-transient error, this request
         *  will fail as well. The method will always execute exactly one of the provided callback
         *  functions.
         *  
         *  @param method: one of the constants provided by the 'HttpMethod' class.
         *  @param path: the path of the resource relative to the root of the game (!).
         *  @param data: the data that will be sent as JSON-encoded body or as URL parameters
         *               (depending on the http method).
         *  @param onComplete: a callback with the form: 
         *                     <pre>onComplete(body:Object, httpStatus:int):void;</pre>
         *  @param onError:    a callback with the form:
         *                     <pre>onError(error:String, httpStatus:int):void;</pre>
         */
        public function request(method:String, path:String, data:Object, 
                                onComplete:Function, onError:Function):void
        {
            if (processQueue())
            {
                // might change before we're in the event handler!
                var auth:Authentication = Flox.authentication;
                
                addEventListener(QueueEvent.QUEUE_PROCESSED, 
                    function onQueueProcessed(event:QueueEvent):void
                    {
                        removeEventListener(QueueEvent.QUEUE_PROCESSED, onQueueProcessed);
                        
                        if (event.success)
                            requestWithAuthentication(method, path, data, auth,
                                                      onComplete, onError);
                        else
                            execute(onError, event.error, event.httpStatus,
                                    method == HttpMethod.GET ? mCache.getObject(path) : null);
                    });
            }
            else
            {
                requestWithAuthentication(method, path, data, Flox.authentication,
                                          onComplete, onError);
            }
        }
        
        /** Adds an asynchronous HTTP request to a queue and immediately starts to process the
         *  queue. */
        public function requestQueued(method:String, path:String, data:Object=null):void
        {
            // To allow developers to use Flox offline, we're optimistic here:
            // even though the operation might fail, we're saving the object in the cache.
            if (method == HttpMethod.PUT) mCache.setObject(path, data);
            
            mQueue.enqueue({ method: method, path: path, data: data,
                             authentication: Flox.authentication });
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
                    var auth:Authentication = element.authentication as Authentication;
                    
                    requestWithAuthentication(element.method, element.path, element.data, 
                                              auth, onRequestComplete, onRequestError);
                }
                else 
                {
                    mProcessingQueue = false;
                    dispatchEvent(new QueueEvent(QueueEvent.QUEUE_PROCESSED));
                }
            }
            
            return mProcessingQueue;
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                mProcessingQueue = false;
                mQueue.dequeue();
                processQueue();
            }
            
            function onRequestError(error:String, httpStatus:int):void
            {
                mProcessingQueue = false;
                
                if (HttpStatus.isTransientError(httpStatus))
                {
                    // server did not answer or is not available! we stop queue processing.
                    Flox.logInfo("Flox Server not reachable (device probably offline). " + 
                                 "HttpStatus: {0}", httpStatus);
                    dispatchEvent(new QueueEvent(QueueEvent.QUEUE_PROCESSED, httpStatus, error));
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
        
        /** Saves request queue and cache index to the disk. */
        public function flush():void
        {
            mQueue.flush();
            mCache.flush();
        }
        
        /** Clears the persistent queue. */
        public function clearQueue():void
        {
            mQueue.clear();
        }
        
        /** Clears the persistent cache. */
        public function clearCache():void
        {
            mCache.clear();
        }
        
        /** Returns an object that was previously received with a GET method from the cache.
         *  If an eTag is given, it must match the object's eTag; otherwise, 
         *  the method returns null. */
        public function getFromCache(path:String, eTag:String=null):Object
        {
            if (mCache.containsKey(path))
            {
                var cachedObject:Object = mCache.getObject(path);
                var cachedETag:String = mCache.getMetaData(path, "eTag").toString();
                
                if (eTag == null || eTag == cachedETag)
                    return cachedObject;
            }
            return null;
        }
        
        // object encoding
        
        /** Encodes an object as parameters for a 'GET' request. */
        private static function encodeForUri(object:Object):String
        {
            var urlVariables:URLVariables = new URLVariables();
            for (var key:String in object) urlVariables[key] = object[key];
            return urlVariables.toString();
        }
        
        /** Encodes an object in JSON format, compresses it and returns its Base64 representation. */
        private static function encode(object:Object):String
        {
            sBuffer.writeUTFBytes(JSON.stringify(object, null, 0));
            sBuffer.compress();
            
            var encodedData:String = Base64.encodeByteArray(sBuffer);
            sBuffer.length = 0;
            
            return encodedData;
        }
        
        /** Decodes an object from JSON format, compressed in a Base64-encoded, zlib-compressed String. */ 
        private static function decode(string:String):Object
        {
            if (string == null || string == "") return null;
            
            Base64.decodeToByteArray(string, sBuffer);
            sBuffer.uncompress();
            
            var json:String = sBuffer.readUTFBytes(sBuffer.length);
            sBuffer.length = 0;
            
            return JSON.parse(json);
        }
        
        // properties
        
        /** @private 
         *  If enabled, all requests will fail. Useful only for unit testing. */
        internal function get alwaysFail():Boolean { return mAlwaysFail; }
        internal function set alwaysFail(value:Boolean):void { mAlwaysFail = value; }
        
        /** The URL pointing to the Flox REST API. */
        public function get url():String { return mUrl; }
        
        /** The unique ID of the game. */
        public function get gameID():String { return mGameID; }
        
        /** The key that identifies the game. */
        public function get gameKey():String { return mGameKey; }
    }
}
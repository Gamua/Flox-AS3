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
    import com.gamua.flox.utils.HttpMethod;
    import com.gamua.flox.utils.HttpStatus;
    import com.gamua.flox.utils.createURL;
    import com.gamua.flox.utils.execute;
    
    import flash.events.Event;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.utils.ByteArray;

    /** A class that makes it easy to communicate with the Flox server via a REST protocol. */
    internal class RestService
    {
        private var mUrl:String;
        private var mGameID:String;
        private var mGameKey:String;
        private var mQueue:PersistentQueue;
        private var mCache:PersistentStore;
        private var mAlwaysFail:Boolean;
        
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
            
            var headers:Object = {};
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
                gameKey: mGameKey,
                bodyCompression: "zlib",
                dispatchTime: DateUtil.toString(new Date())
            };
            
            headers["Content-Type"] = "application/json";
            headers["X-Flox"] = xFloxHeader;
            
            if (method == HttpMethod.GET && mCache.containsKey(path))
                headers["If-None-Match"] = mCache.getMetaData(path, "eTag");
            
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
                                result = mCache.getObject(path);
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
                        var error:String = body ? body.message : "unknown";
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
        
        /** Makes an asynchronous HTTP request at the server. The method will always execute
         *  exactly one of the provided callback functions.
         *  
         *  @param method: one of the methods provided by the 'HttpMethod' class.
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
            requestWithAuthentication(method, path, data, Flox.authentication,
                                      onComplete, onError);
        }
        
        /** Adds an asynchronous HTTP request to a queue and immediately starts to process the
         *  queue. */
        public function requestQueued(method:String, path:String, data:Object=null, 
                                      headers:Object=null):void
        {
            mQueue.enqueue({ method: method, path: path, data: data, headers: headers,
                             authentication: Flox.authentication });
            processQueue();
        }
        
        /** Processes the request queue, executing requests in the order they were recorded.
         *  If the server cannot be reached, processing stops and is retried later; if a request
         *  produces an error, it is discarded. 
         *  @returns true if the queue is currently being processed. */
        public function processQueue():Boolean
        {
            if (!mQueue.isLocked)
            {
                if (mQueue.length > 0)
                {
                    mQueue.isLocked = true;
                    var element:Object = mQueue.peek();
                    requestWithAuthentication(element.method, element.path, element.data, 
                        element.authentication, onRequestComplete, onRequestError);
                }
                else mQueue.isLocked = false;
            }
            
            return mQueue.isLocked;
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                mQueue.isLocked = false;
                mQueue.dequeue();
                processQueue();
            }
            
            function onRequestError(error:String, httpStatus:int):void
            {
                mQueue.isLocked = false;
                
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
        public function flush():void
        {
            mQueue.flush();
        }
        
        /** Clears cache and queue from the persistent storage. */
        public function clearPersistentData():void
        {
            mQueue.clear();
            mCache.clear();
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
            if (string == null) return null;
            
            Base64.decodeToByteArray(string, sBuffer);
            sBuffer.uncompress();
            
            var json:String = sBuffer.readUTFBytes(sBuffer.length);
            sBuffer.length = 0;
            
            return JSON.parse(json);
        }
        
        // properties
        
        /** If enabled, all requests will fail. Useful only for unit testing. */
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
package com.gamua.flox
{
    import com.gamua.flox.utils.XmlConvert;
    import com.gamua.flox.utils.createURL;
    import com.gamua.flox.utils.execute;
    import com.hurlant.crypto.hash.SHA256;
    import com.hurlant.util.Base64;
    
    import flash.events.Event;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.utils.ByteArray;

    public class HttpManager
    {
        private static const CACHE_STORE:String = "HttpManager.Cache";
        private static const QUEUE_STORE:String = "HttpManager.Queue";
        
        private static var sBaseUrl:String;
        private static var sProcessingQueue:Boolean = false;
        private static var sSharedData:Object = {};
        
        public function HttpManager() { throw new Error("This class cannot be instantiated."); }
        
        public static function init(baseUrl:String):void
        {
            PersistentStore.registerClass(CacheEntry);
            sBaseUrl = baseUrl;
            processQueue();
        }
        
        public static function postQueued(url:String, params:Object, key:String):void
        {
            queue.push([url, params, key]);
            processQueue();
        }
        
        public static function processQueue(tries:int=3):int
        {
            var queueLength:int = queue.length;
            if (sProcessingQueue || queueLength == 0 || tries <= 0) return queueLength;
            
            var args:Array = queue[0];
            sProcessingQueue = true;
            post(args[0], args[1], args[2], onComplete, onError);
            
            return queueLength;
            
            function onComplete():void
            {
                sProcessingQueue = false;
                queue.shift();
                processQueue(tries);
            }
            
            function onError():void
            {
                sProcessingQueue = false;
                processQueue(tries-1); 
            }
        }
        
        public static function get queueLength():int
        {
            return queue.length;
        }
        
        // onComplete(httpStatus);
        // onError(error:String);
        public static function post(url:String, params:Object, key:String,
                                    onComplete:Function=null, onError:Function=null):void
        {
            var httpStatus:int = -1;
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onLoaderComplete);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
            loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onLoaderHttpStatus);
            
            var request:URLRequest = new URLRequest(createURL(sBaseUrl, url));
            request.data = createUrlVariables(params, null, key);
            request.method = URLRequestMethod.POST;
            
            loader.load(request);
            
            function onLoaderComplete(event:Event):void
            {
                if (httpStatus == 204) // 'No Content'
                    execute(onComplete, httpStatus);
                else
                    execute(onError, "HTTP Status " + httpStatus); 
            }
            
            function onLoaderError(event:IOErrorEvent):void
            {
                // any httpStatus > 0 that leads us into this callback means there was an error
                // for which we need to get an error message. Unfortunately, AS3 does not support
                // getting the error body, so we're doing this in a separate request.
                
                if (httpStatus > 0)
                    getError(request.data.requestId, onError);
                else
                    execute(onError, event.text);
            }
            
            function onLoaderHttpStatus(event:HTTPStatusEvent):void
            {
                httpStatus = event.status;
            }
        }
        
        // onComplete(xml:XML, fromCache:Boolean);
        // onError(error:String);
        public static function getXml(url:String, params:Object,
                                      onComplete:Function, onError:Function):void
        {
            var key:String = createUrlKey(url, params);
            var cacheEntry:CacheEntry = loadFromCache(key);
            var eTag:String = cacheEntry ? cacheEntry.eTag : null;
            var httpStatus:int = -1;
            
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onLoaderComplete);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
            loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onLoaderHttpStatus);
            
            var request:URLRequest = new URLRequest(createURL(sBaseUrl, url));
            request.data = createUrlVariables(params, eTag);
            
            loader.load(request);
            
            function onLoaderComplete(event:Event):void
            {
                if (httpStatus == 200) // OK
                {
                    var dataString:String = loader.data as String;
                    var dataXml:XML = XML(dataString);
                    saveToCache(key, dataString, dataXml.@eTag.toString());
                    execute(onComplete, dataXml, false);
                }
                else if (httpStatus == 304) // not modified
                {
                    execute(onComplete, cacheEntry.dataAsXml, true);
                }
                else
                    execute(onError, "HTTP Status " + httpStatus);
            }
            
            function onLoaderError(event:IOErrorEvent):void
            {
                // any httpStatus > 0 that leads us into this callback means there was an error
                // for which we need to get an error message. Unfortunately, AS3 does not support
                // getting the error body, so we're doing this in a separate request.
                
                if (httpStatus > 0)
                    getError(request.data.requestId, onError);
                else
                    execute(onError, event.text);
            }
            
            function onLoaderHttpStatus(event:HTTPStatusEvent):void
            {
                httpStatus = event.status;
            }
        }
        
        // onComplete(error:String);
        private static function getError(requestID:String, onComplete:Function):void
        {
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onLoaderComplete);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
            
            var request:URLRequest = new URLRequest(createURL(sBaseUrl, "errors", requestID));
            loader.load(request);
            
            function onLoaderComplete(event:Event):void
            {
                var data:XML = XML(loader.data as String);
                execute(onComplete, data.toString());
            }
            
            function onLoaderError(event:IOErrorEvent):void
            {
                execute(onComplete, event.text);
            }
        }
        
        public static function clearCache():void
        {
            PersistentStore.set(CACHE_STORE, {});
        }
        
        public static function clearQueue():void
        {
            PersistentStore.set(QUEUE_STORE, []);
        }
        
        private static function createUrlVariables(params:Object=null, eTag:String=null,
                                                   key:String=null):URLVariables
        {
            var variables:URLVariables = new URLVariables();
            
            variables["sdkType"] = "as3";
            variables["sdkVersion"] = Flox.VERSION;
            variables["requestId"] = uint(Math.random() * uint.MAX_VALUE);
            variables["dispatchTime"] = XmlConvert.dateToString(new Date());
            
            if (params)
                for (var name:String in params)
                    variables[name] = params[name];
            
            if (eTag && eTag != "")
                variables["If-None-Match"] = eTag;
            
            if (key)
                variables["digest"] = createDigest(key, variables);
            
            return variables;
        }
        
        private static function createDigest(gameKey:String, params:Object):String
        {
            var keys:Array = [];
            for (var key:String in params) keys.push(key);
            keys.sort();
            
            var content:String = gameKey;
            for each (key in keys) content += "|" + params[key];
            
            var data:ByteArray = new ByteArray();
            data.writeUTFBytes(content);
            
            var sha:SHA256 = new SHA256();
            return Base64.encodeByteArray(sha.hash(data));
        }

        private static function createUrlKey(url:String, params:Object):String
        {
            var suffix:String = "";
            
            for (var key:String in params)
                suffix += escape(key) + "=" + escape(params[key]) + "&";
            
            if (suffix.length == 0) return url;
            else return url + "?" + suffix;
        }
        
        private static function saveToCache(key:String, value:String, eTag:String=null):void
        {
            var data:ByteArray = new ByteArray();
            data.writeUTF(value);
            data.compress();
            cache[key] = new CacheEntry(data, eTag);
        }
        
        private static function loadFromCache(key:String):CacheEntry
        {
            return cache[key] as CacheEntry;
        }
        
        private static function deleteFromCache(prefix:String):void
        {
            var cache:Object = HttpManager.cache;
            
            for (var key:String in cache)
                if (key.indexOf(prefix) == 0) delete cache[key]; 
        }
        
        private static function get cache():Object
        {
            if (PersistentStore.get(CACHE_STORE) == null) PersistentStore.set(CACHE_STORE, []);
            return PersistentStore.get(CACHE_STORE);
        }
        
        private static function get queue():Array
        {
            if (PersistentStore.get(QUEUE_STORE) == null) PersistentStore.set(QUEUE_STORE, []);
            return PersistentStore.get(QUEUE_STORE) as Array;
        }
    }
}

import flash.utils.ByteArray;

class CacheEntry
{
    public var data:ByteArray;
    public var eTag:String;
    
    public function CacheEntry(data:ByteArray=null, eTag:String=null)
    {
        this.data = data;
        this.eTag = eTag ? eTag : "";
    }
    
    public function get uncompressedData():ByteArray
    {
        var clone:ByteArray = new ByteArray();
        clone.writeBytes(data);
        clone.uncompress();
        return clone;
    }
    
    public function get dataAsString():String
    {
        return uncompressedData.readUTF();
    }
    
    public function get dataAsXml():XML
    {
        return XML(dataAsString);
    }
}
package com.gamua.flox
{
    import com.gamua.flox.utils.execute;
    
    import flash.events.Event;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.net.SharedObject;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLVariables;
    import flash.net.registerClassAlias;
    import flash.utils.ByteArray;
    import flash.utils.getQualifiedClassName;

    public class HttpManager
    {
        public function HttpManager() { throw new Error("This class cannot be instantiated."); }
        
        public static function init():void
        {
            registerClassAlias(getQualifiedClassName(CacheEntry), CacheEntry);
        }
        
        // onComplete(xml:XML, fromCache:Boolean);
        // onError(error:String, httpStatus:int);
        public static function getXml(url:String, params:Object,
                                      onComplete:Function, onError:Function):void
        {
            var key:String = createUrlKey(url, params);
            var cacheEntry:CacheEntry = loadFromCache(key);
            var eTag:String = cacheEntry ? cacheEntry.eTag : null;
            var httpStatus:int = 0;
            
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onLoaderComplete);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
            loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onLoaderHttpStatus);
            
            var request:URLRequest = new URLRequest(url);
            request.data = createUrlVariables(eTag, params);
            
            loader.load(request);
            
            function onLoaderComplete(event:Event):void
            {
                if (httpStatus == 200)
                {
                    var dataString:String = loader.data as String;
                    var dataXml:XML = XML(dataString);
                    saveToCache(key, dataXml.@eTag.toString(), dataString);
                    execute(onComplete, dataXml, false);
                }
                else if (httpStatus == 304)
                {
                    execute(onComplete, cacheEntry.dataAsXml, true);
                }
                else
                    execute(onError, "Unexpected HTTP Status: " + httpStatus, httpStatus);
            }
            
            function onLoaderError(event:IOErrorEvent):void
            {
                execute(onError, "IOError: " + event.text, httpStatus);
            }
            
            function onLoaderHttpStatus(event:HTTPStatusEvent):void
            {
                httpStatus = event.status;
            }
        }
        
        public static function clearCache():void
        {
            deleteFromCache("");
        }
        
        private static function createUrlVariables(eTag:String=null, params:Object=null):URLVariables
        {
            var variables:URLVariables = new URLVariables();
            
            variables["sdk-type"] = "as3";
            variables["sdk-version"] = Flox.VERSION;
            
            if (variables)
                for (var name:String in params)
                    variables[name] = params[name];
            
            if (eTag && eTag != "") 
                variables["If-None-Match"] = eTag;
            
            return variables;
        }
        
        private static function createUrlKey(url:String, params:Object):String
        {
            var urlKey:String = url + "?";
            
            for (var key:String in params)
                urlKey += escape(key) + "=" + escape(params[key]) + "&";
            
            return urlKey;
        }
        
        private static function saveToCache(key:String, eTag:String, value:String):void
        {
            var data:ByteArray = new ByteArray();
            data.writeUTF(value);
            data.compress();
            cache[key] = new CacheEntry(eTag, data);
            sharedObject.flush();
        }
        
        private static function loadFromCache(key:String):CacheEntry
        {
            var cacheEntry:CacheEntry = cache[key] as CacheEntry;
            
            if (cacheEntry == null) return null;
            else return cacheEntry;
        }
        
        private static function deleteFromCache(prefix:String):void
        {
            var cache:Object = HttpManager.cache;
            
            for (var key:String in cache)
                if (key.indexOf(prefix) == 0) delete cache[key]; 
        }
        
        private static function get cache():Object
        {
            return sharedObject.data;
        }
        
        private static function get sharedObject():SharedObject 
        { 
            return SharedObject.getLocal("Flox-HttpManager");
        }
    }
}

import flash.utils.ByteArray;

class CacheEntry
{
    public var eTag:String;
    public var data:ByteArray;
    
    public function CacheEntry(eTag:String=null, data:ByteArray=null)
    {
        this.eTag = eTag ? eTag : "";
        this.data = data;
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
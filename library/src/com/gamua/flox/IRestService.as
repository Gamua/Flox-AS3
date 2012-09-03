// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    /** An interface providing a way to communicate with the Flox server via a REST protocol. */
    internal interface IRestService
    {
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
        function request(method:String, path:String, data:Object, headers:Object,
                         onComplete:Function, onError:Function):void;
        
        /** Adds an asynchronous HTTP request to a queue and immediately starts to process the
         *  queue. */
        function requestQueued(method:String, path:String, data:Object=null,
                               headers:Object=null):void;
        
        /** Processes the request queue, executing requests in the order they were recorded.
         *  If the server cannot be reached, processing stops and is retried later; if a request
         *  produces an error, it is discarded. 
         *  @returns true if the queue is currently being processed. */
        function processQueue():Boolean;
    }
}
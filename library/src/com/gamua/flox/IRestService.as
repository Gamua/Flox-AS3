// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    internal interface IRestService
    {
        // onComplete(body:Object, eTag:String, httpStatus:int):void
        // onError(error:String, eTag:String, httpStatus:int):void
        function request(method:String, path:String, data:Object, headers:Object,
                         onComplete:Function, onError:Function):void;
        
        function requestQueued(method:String, path:String, data:Object=null,
                               headers:Object=null):void;
        
        function processQueue():Boolean;
    }
}
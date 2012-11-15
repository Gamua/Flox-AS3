// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox.utils
{
    /** Provides a list of HTTP methods (verbs). */
    public class HttpStatus
    {
        public function HttpStatus() { throw new Error("This class cannot be instantiated."); }
        
        /** Everything is OK. */
        public static const OK:int = 200;
        
        /** Everything is OK, but there's nothing to return. */
        public static const NO_CONTENT:int = 204; 
        
        /** An If-None-Match precondition failed in a GET request. */
        public static const NOT_MODIFIED:int = 304;
        
        /** The request is missing information, e.g. parameters. */
        public static const BAD_REQUEST:int = 400;
        
        /** An authentication error occured. */
        public static const FORBIDDEN:int = 403;
        
        /** The requested resource is not available. */
        public static const NOT_FOUND:int = 404;
        
        /** An If-Match precondition failed in a PUT/POST request. */
        public static const PRECONDITION_FAILED:int = 412;
        
        /** Something unexpected happened within server code. */
        public static const INTERNAL_SERVER_ERROR:int = 500;
        
        /** Accessing this resource has not yet been implemented */
        public static const NOT_IMPLEMENTED:int = 501;
        
        /** The server is down for maintenance. */
        public static const SERVICE_UNAVAILABLE:int = 503;
        
        public static function isSuccess(status:int):Boolean
        {
            return status > 0 && status < 400;
        }
        
        public static function isTransientError(status:int):Boolean
        {
            return status == 0 || status == SERVICE_UNAVAILABLE;
        }
    }
}
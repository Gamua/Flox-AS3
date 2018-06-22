// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox.utils
{
    /** Provides a list of HTTP status codes that are returned by the Flox server. */
    public final class HttpStatus
    {
        /** @private */
        public function HttpStatus() { throw new Error("This class cannot be instantiated."); }
        
        /** We don't know the actual HTTP status. */
        public static const UNKNOWN:int = 0;
        
        /** Everything is OK. */
        public static const OK:int = 200;
        
        /** The request has been accepted for processing, but processing has not been completed. */
        public static const ACCEPTED:int = 202;
        
        /** Everything is OK, but there's nothing to return. */
        public static const NO_CONTENT:int = 204; 
        
        /** An If-None-Match precondition failed in a GET request. */
        public static const NOT_MODIFIED:int = 304;
        
        /** The request is missing information, e.g. parameters. */
        public static const BAD_REQUEST:int = 400;
        
        /** Used by 'Player.loginWithEmailAndPassword' to indicate that a confirmation mail
         *  has been sent to the player. */
        public static const UNAUTHORIZED:int = 401;

        /** An authentication error occurred. */
        public static const FORBIDDEN:int = 403;
        
        /** The requested resource is not available. */
        public static const NOT_FOUND:int = 404;
        
        /** The request timed out. */
        public static const REQUEST_TIMEOUT:int = 408;

        /** An If-Match precondition failed in a PUT/POST request. */
        public static const PRECONDITION_FAILED:int = 412;
        
        /** The user has sent too many requests in a given amount of time. */  
        public static const TOO_MANY_REQUESTS:int = 429;
        
        /** Something unexpected happened within server code. */
        public static const INTERNAL_SERVER_ERROR:int = 500;
        
        /** Accessing this resource has not yet been implemented */
        public static const NOT_IMPLEMENTED:int = 501;
        
        /** The server is down for maintenance. */
        public static const SERVICE_UNAVAILABLE:int = 503;
        
        /** Indicates if a status code depicts a success or a failure. */
        public static function isSuccess(status:int):Boolean
        {
            return status > 0 && status < 400;
        }
        
        /** Indicates if an error might go away if the request is tried again (i.e. the server
         *  was not reachable or there was a network error). */
        public static function isTransientError(status:int):Boolean
        {
            return status == UNKNOWN || status == SERVICE_UNAVAILABLE || status == REQUEST_TIMEOUT;
        }

        /** Returns a string representation of the given status code. */
        public static function toString(status:int):String
        {
            switch (status)
            {
                case OK: return "ok";
                case ACCEPTED: return "accepted";
                case NO_CONTENT: return "noContent";
                case NOT_MODIFIED: return "notModified";
                case BAD_REQUEST: return "badRequest";
                case UNAUTHORIZED: return "unAuthorized";
                case FORBIDDEN: return "forbidden";
                case NOT_FOUND: return "notFound";
                case REQUEST_TIMEOUT: return "requestTimeout";
                case PRECONDITION_FAILED: return "preconditionFailed";
                case TOO_MANY_REQUESTS: return "tooManyRequest";
                case INTERNAL_SERVER_ERROR: return "internalServerError";
                case NOT_IMPLEMENTED: return "notImplemented";
                case SERVICE_UNAVAILABLE: return "serviceUnavailable";
                default: return "unknown";
            }
        }
    }
}
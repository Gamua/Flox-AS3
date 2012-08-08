// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox.utils
{
    public class HttpMethod
    {
        public function HttpMethod() { throw new Error("This class cannot be instantiated."); }
        
        public static const GET:String    = "get";
        public static const POST:String   = "post";
        public static const PUT:String    = "put";
        public static const DELETE:String = "delete";
    }
}
// =================================================================================================
//
//	Flox AS3
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    /** A utility class providing strings of authentication types. This class contains all
     *  types that are currently supported by Flox, and will contain identifiers for Facebook,
     *  twitter and the likes. */
    internal final class AuthenticationType
    {
        public function AuthenticationType() 
        { 
            throw new Error("This class cannot be instantiated."); 
        }
     
        /** A guest account, i.e. the user is not authenticated at all. */
        public static const GUEST:String    = "guest";
        // public static const EMAIL:String    = "email";
        // public static const FACEBOOK:String = "facebook";
        // public static const TWITTER:String  = "twitter";
        // public static const GAMUA:String    = "gamua";
    }
}
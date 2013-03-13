// =================================================================================================
//
//	Flox AS3
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    /** A utility class providing strings of authentication types. This class contains all
     *  types that are currently supported by Flox. It will be extended with additional types in 
     *  the future. */
    public final class AuthenticationType
    {
        /** @private */
        public function AuthenticationType() 
        { 
            throw new Error("This class cannot be instantiated."); 
        }
     
        /** A guest account, i.e. the user is not authenticated at all. */
        public static const GUEST:String = "guest";
        
        /** Knowledge of a single identifier allows theh player to login. */
        public static const KEY:String = "key";
        
        /** The user proves to have access to a certain e-mail address. */
        public static const EMAIL:String = "email";
        
        // public static const FACEBOOK:String = "facebook";
        // public static const TWITTER:String  = "twitter";
        // public static const GAMUA:String    = "gamua";
    }
}
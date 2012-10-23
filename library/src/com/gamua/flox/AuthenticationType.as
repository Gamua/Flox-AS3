package com.gamua.flox
{
    internal final class AuthenticationType
    {
        public function AuthenticationType() 
        { 
            throw new Error("This class cannot be instantiated."); 
        }
        
        public static const GUEST:String    = "guest";
        // public static const FACEBOOK:String = "facebook";
        // public static const TWITTER:String  = "twitter";
        // public static const GAMUA:String    = "gamua";
    }
}
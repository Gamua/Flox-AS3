// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox.utils
{
    import flash.crypto.generateRandomBytes;
    import flash.utils.ByteArray;

    /**
     *  Generates a UID (unique identifier) that can be used for Entity IDs. Per default, the
     *  UID is 16 characters long and is based on ActionScript's "flash.crypto" random number
     *  generator.
     *  
     *  <p>When you pass a seed, the String is instead based on the SHA-256 hash of the seed.
     *  Each seed will always produce the same result. The maximum length of a seeded UID is
     *  43 characters (the full SHA-256 length).</p>
     *  
     *  <p>Note: do not use this function for security-critical hashing; to limit the result to
     *  an alphanumeric String, it uses the SHA-256 algorithm in a special way. If you need
     *  perfect security, use the SHA256 class directly.</p>
     */
    public function createUID(length:int=16, seed:String=null):String
    {
        var bytes:ByteArray;
        var b64:String = null;

        if (length == 0) return "";
        else if (seed)
        {
            if (length > 43)
                throw new Error("Maximum length of seeded UID is 43 characters");
            
            while (b64 == null || b64.indexOf("/") != -1 || b64.indexOf("+") != -1)
            {
                b64 = SHA256.hashString(seed).replace("=", "").substr(0, length);
                seed += b64.charAt(0);
            }
        }
        else
        {
            bytes = flash.crypto.generateRandomBytes(length);
            b64 = Base64.encodeByteArray(bytes).substr(0, length);
            
            while (b64.indexOf("/") != -1) b64 = b64.replace("/", getRandomChar());
            while (b64.indexOf("+") != -1) b64 = b64.replace("+", getRandomChar());
        }
        
        return b64; 
    }
}

const ALLOWED_CHARS:String = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
const NUM_ALLOWED_CHARS:int = 62;

function getRandomChar():String
{
    return ALLOWED_CHARS.charAt(int(Math.random() * NUM_ALLOWED_CHARS));
}
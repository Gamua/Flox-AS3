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
     *  Generates a UID (unique identifier) based on ActionScript's "flash.crypto" random number
     *  generator. The UID contains 16 alphanumeric characters. 
     */
    public function createUID():String
    {
        var bytes:ByteArray = flash.crypto.generateRandomBytes(12);
        var b64:String = Base64.encodeByteArray(bytes);
        
        while (b64.indexOf("/") != -1) b64 = b64.replace("/", getRandomChar());
        while (b64.indexOf("+") != -1) b64 = b64.replace("+", getRandomChar());
        
        return b64; 
    }
}

const ALLOWED_CHARS:String = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
const NUM_ALLOWED_CHARS:int = 62;

function getRandomChar():String
{
    return ALLOWED_CHARS.charAt(int(Math.random() * NUM_ALLOWED_CHARS));
}
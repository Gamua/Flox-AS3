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
     *  Generates a UID (unique identifier) based on ActionScript's pseudo-random 
     *  number generator and the current time.
     *
     *  <p>The UID contains only alphanumeric chars and has a length of 22 characters. It will
     *  not be truly globally unique; but it is the best we can do without player support for 
     *  UID generation.</p>
     */
    public function createUID():String
    {
        // By incorporating both the current time and "flash.crypto",
        // we hope to create the best possible result.
        
        var bytes:ByteArray = flash.crypto.generateRandomBytes(10);
        bytes.position = bytes.length;
        bytes.writeDouble(new Date().time);
        
        var b64:String = Base64.encodeByteArray(bytes).substr(0, 22);
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
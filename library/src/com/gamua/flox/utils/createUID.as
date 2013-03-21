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
     *  <p>The UID uses alphanumeric chars and has a length of 22 characters. It will not be truly
     *  globally unique; but it is the best we can do without player support for UID generation.</p>
     */
    public function createUID():String
    {
        var bytes:ByteArray = flash.crypto.generateRandomBytes(10);
        bytes.position = bytes.length;
        bytes.writeDouble(new Date().time);
        return Base64.encodeByteArray(bytes).replace(/\//g, "_").replace(/\+/g, "-").substr(0, 22); 
    }
}
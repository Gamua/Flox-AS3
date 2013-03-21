// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox.utils
{
    /**
     *  Generates a UID (unique identifier) based on ActionScript's pseudo-random 
     *  number generator and the current time.
     *
     *  <p>The UID uses alphanumeric chars and has a length of 22 characters. It will not be truly
     *  globally unique; but it is the best we can do without player support for UID generation.</p>
     */
    public function createUID():String
    {
        var uid:Array = new Array(14);
        var i:int;
        
        if (CHAR_CODES == null)
        {
            CHAR_CODES = [];
            for (i=48; i<=57;  ++i) CHAR_CODES.push(i);
            for (i=65; i<=90;  ++i) CHAR_CODES.push(i);
            for (i=97; i<=122; ++i) CHAR_CODES.push(i);
            NUM_CHAR_CODES = CHAR_CODES.length;
        }
        
        // index  0-13: random chars 
        // index 14-21: encoded time
        
        // Note: time is the number of milliseconds since 1970, which is currently more than one 
        // trillion. Just in case the system clock has been reset to 1970 
        // (in which case the string might be too short), we pad on the left with 7 zeros.

        for (i=0; i<14; ++i)
            uid[i] = CHAR_CODES[int(Math.random() * NUM_CHAR_CODES)];
        
        var numberString:String = String.fromCharCode.apply(null, uid);
        var timeString:String = ("0000000" + new Date().time.toString(36)).substr(-8);
        
        return numberString + timeString;
    }
}

var CHAR_CODES:Array = null;
var NUM_CHAR_CODES:int;
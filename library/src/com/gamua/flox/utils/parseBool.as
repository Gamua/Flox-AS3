// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox.utils
{
    /** Parses a string containing a boolean value (yes/no, true/false, 1/0). */
    public function parseBool(str:String):Boolean
    {
        var value:String = str.toLowerCase();
        if (str == "true" || str == "yes") return true;
        else return false;
    }
}
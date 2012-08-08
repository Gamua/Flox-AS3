// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox.utils
{
    /** Joins all arguments with a forward slash while avoiding double slashes. */
    public function createURL(...args):String
    {
        if (args.length == 1 && args[0] is Array)
            args = args[0];
        
        for (var i:int=0; i<args.length; ++i)
        {
            var element:String = args[i];
            if (element == null || element == "") { args.splice(i, 1); i--; continue; }
 
            var start:int = 0;
            if (i != 0 && element.indexOf("/") == 0) start = 1;
            
            var end:int = int.MAX_VALUE;
            if (i != args.length-1 && element.lastIndexOf("/") == element.length-1) end = -1; 
            
            args[i] = element.slice(start, end);
        }
        
        return args.join("/");
    }
}
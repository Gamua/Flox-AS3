package com.gamua.flox.utils
{
    /** Formats a String in .Net-style, with curly braces ("{0}"). Does not support any 
     *  number formatting options yet. */
    public function formatString(format:String, ...args):String
    {
        if (args.length == 1 && (args[0] is Array || args[0] is Vector))
            args = args[0];
        
        for (var i:int=0; i<args.length; ++i)
            format = format.replace(new RegExp("\\{"+i+"\\}", "g"), args[i]);
        
        return format;
    }
}
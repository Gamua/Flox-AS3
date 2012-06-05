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
            var start:int = element.indexOf("/") == 0 ? 1 : 0;
            var end:int = element.lastIndexOf("/") == element.length - 1 ? -1 : int.MAX_VALUE;
            args[i] = element.slice(start, end);
        }
        
        return args.join("/");
    }
}
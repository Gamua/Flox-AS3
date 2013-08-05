// =================================================================================================
//
//	Flox AS3
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox.utils
{
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;

    /** Executes a method with the given arguments after a certain number of milliseconds.
     *  The difference to the corresponding method in the 'flash.utils' package is that
     *  'clearTimeout' is called automatically after the closure was executed, which avoids
     *  memory leaks. */
    public function setTimeout(closure:Function, delay:int, ...args):uint
    {
        var timeoutID:uint = flash.utils.setTimeout.call(null, onTimeout, delay, args);
        return timeoutID;
        
        function onTimeout(args:Array):void
        {
            flash.utils.clearTimeout(timeoutID);
            closure.apply(null, args);
        }
    }
}
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

    /** Executes a method with the given arguments after a certain number of seconds.
     *  The difference to the corresponding method in the 'flash.utils' package is that
     *  'delay' is in seconds (not milliseconds) and that 'clearTimeout' is called automatically
     *  after the closure was executed. */
    public function setTimeout(closure:Function, delay:Number, ...args):uint
    {
        var timeoutID:uint = flash.utils.setTimeout.call(null, onTimeout, delay * 1000, args);
        return timeoutID;
        
        function onTimeout(args:Array):void
        {
            flash.utils.clearTimeout(timeoutID);
            closure.apply(null, args);
        }
    }
}
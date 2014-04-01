// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox.utils
{
    /** Executes a function with the specified arguments. If the argument count does not match
     *  the function, the argument list is cropped / filled up with <code>null</code> values. */
    public function execute(func:Function, ...args):void
    {
        if (func != null)
        {
            var i:int;
            var maxNumArgs:int = func.length;

            for (i=args.length; i<maxNumArgs; ++i)
                args[i] = null;

            func.apply(null, args.slice(0, maxNumArgs));
        }
    }
}
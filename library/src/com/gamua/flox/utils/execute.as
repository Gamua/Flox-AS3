// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox.utils
{
    /** Executes a method with the number of accepted parameters. */
    public function execute(func:Function, ...args):void
    {
        if (func != null)
        {
            if      (func.length == 0) func();
            else if (func.length == 1) func(args[0]);
            else if (func.length == 2) func(args[0], args[1]);
            else if (func.length == 3) func(args[0], args[1], args[2]);
            else if (func.length == 4) func(args[0], args[1], args[2], args[3]);
            else if (func.length == 5) func(args[0], args[1], args[2], args[3], args[4]);
            else throw new ArgumentError("This method is limited to 5 parameters.");
        }
    }
}
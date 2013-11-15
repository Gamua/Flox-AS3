// =================================================================================================
//
//	Flox AS3
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    /** A utility class providing strings of access types. */
    public final class Access
    {
        /** @private */
        public function Access() 
        {
            throw new Error("This class cannot be instantiated."); 
        }
        
        /** No access. */
        public static const NONE:String = "";
        
        /** Read-only access. */
        public static const READ:String = "r";
        
        /** Read and write access, including deletion. */
        public static const READ_WRITE:String = "rw";
    }
}
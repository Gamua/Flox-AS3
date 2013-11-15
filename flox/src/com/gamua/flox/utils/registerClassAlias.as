// =================================================================================================
//
//	Flox AS3
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox.utils
{
    import flash.net.registerClassAlias;
    import flash.utils.getQualifiedClassName;

    /** Preserves the class (type) of an object when the object is encoded in Action Message
     *  Format (AMF). Different to the 'flash.net' variant, this method defaults to the
     *  qualified class name of the class object. */
    public function registerClassAlias(classObject:Class, aliasName:String=null):void
    {
        if (aliasName == null) aliasName = getQualifiedClassName(classObject);
        flash.net.registerClassAlias(aliasName, classObject);
    }
}

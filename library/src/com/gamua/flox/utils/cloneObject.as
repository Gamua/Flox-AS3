// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox.utils
{
    /** Creates a deep copy of the object. 
     *  Beware: all complex data types will become mere 'Object' instances. Supported are only
     *  primitive data types, arrays and objects. */
    public function cloneObject(object:Object):Object
    {
        if (object is Number || object is String || object is Boolean || object == null)
            return object;
        else if (object is Array)
        {
            var array:Array = object as Array;
            var arrayClone:Array = [];
            var length:int = array.length;
            for (var i:int=0; i<length; ++i) arrayClone[i] = cloneObject(array[i]);
            return arrayClone;
        }
        else
        {
            var objectClone:Object = {};
            for (var key:String in object) objectClone[key] = cloneObject(object[key]);
            return objectClone;
        }
    }
}
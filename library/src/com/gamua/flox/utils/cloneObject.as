// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox.utils
{
    import flash.utils.getQualifiedClassName;

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
            
            if (getQualifiedClassName(object) == "Object")
            {
                for (var key:String in object) 
                    objectClone[key] = cloneObject(object[key]);
            }
            else
            {
                for each (var accessor:XML in describeType(object).accessor)
                {
                    var access:String = accessor.@access.toString();
                    var accessorName:String = accessor.@name.toString();
                    
                    if (access == "readwrite" || access == "read") 
                        objectClone[accessorName] = cloneObject(object[accessorName]);
                }
            }
            
            return objectClone;
        }
    }
}
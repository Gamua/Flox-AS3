// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox.utils
{
    import flash.utils.describeType;
    import flash.utils.getQualifiedClassName;

    /** Produces an XML object that describes the ActionScript object named as the parameter of 
     *  the method. Different to the 'flash.utils.describeType' method, this one caches its results,
     *  so each class will be analyzed only once. */
    public function describeType(value:*):XML
    {
        var type:String = getQualifiedClassName(value);
        var description:XML = cache[type];
        
        if (description == null)
        {
            description = flash.utils.describeType(value);
            cache[type] = description;
        }
        
        return description;
    }
}

import flash.utils.Dictionary;
var cache:Dictionary = new Dictionary();
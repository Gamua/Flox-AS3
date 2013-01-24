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
     *  the method. The results are a little different from the 'flash.utils' method with the
     *  same name: passing an instance or its class produces the same results, and that result
     *  is being cached. */ 
    public function describeType(value:*):XML
    {
        var type:String = getQualifiedClassName(value);
        var description:XML = cache[type];
        
        if (description == null)
        {
            // We always use the underlying class and return the factory element.
            // That way, the type description is always the same, no matter if you pass
            // the class or an instance of it.
            
            if (!(value is Class))
                value = Object(value).constructor;
        
            description = XML(flash.utils.describeType(value).factory);
            cache[type] = description;
        }
        
        return description;
    }
}

import flash.utils.Dictionary;
var cache:Dictionary = new Dictionary();
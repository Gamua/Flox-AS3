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
     *  primitive data types, arrays and objects. Any properties marked with "NonSerialized" 
     *  meta data will be ignored by this method. 
     * 
     *  <p>Optionally, you can pass a 'filter' function. It will be called on any child object.
     *  You can use this filter to create custom serializations. The following sample exchanges
     *  every 'Date' instance with a custom string.</p>
     * 
     *  <pre>
     *  clone:Object = cloneObject(original, function(object:Object):Object
     *      {
     *          if (object is Date) return DateUtil.toString(object as Date);
     *          else return null; // 'null' causes default behaviour
     *      });</pre>
     */
    public function cloneObject(object:Object, filter:Function=null):Object
    {
        if (filter != null)
        {
            var filteredClone:Object = filter(object);
            if (filteredClone) return filteredClone;
        }
        
        if (object is Number || object is String || object is Boolean || object == null)
            return object;
        else if (object is Array)
        {
            var array:Array = object as Array;
            var arrayClone:Array = [];
            var length:int = array.length;
            for (var i:int=0; i<length; ++i) arrayClone[i] = cloneObject(array[i], filter);
            return arrayClone;
        }
        else 
        {
            var objectClone:Object = {};
            var typeDescription:XML = null;
            
            if (getQualifiedClassName(object) == "Object")
            {
                for (var key:String in object) 
                    objectClone[key] = cloneObject(object[key], filter);
            }
            else
            {
                typeDescription = describeType(object);
                var properties:XMLList = typeDescription.variable + typeDescription.accessor;
                
                for each (var property:XML in properties)
                {
                    var propertyName:String = property.@name.toString();
                    var access:String = property.@access.toString(); 
                    var nonSerializedMetaData:XMLList = property.metadata.(@name == "NonSerialized");
                    
                    if (access != "writeonly" && nonSerializedMetaData.length() == 0)
                        objectClone[propertyName] = cloneObject(object[propertyName], filter);
                }
            }
            
            return objectClone;
        }
    }
}
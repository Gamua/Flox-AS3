// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.utils.cloneObject;
    import com.gamua.flox.utils.createUID;
    
    import flash.net.SharedObject;

    /** A data store that uses SharedObjects to save its contents to the disk. Objects are
     *  serialized using the AMF format, so be sure to use either primitive objects or classes to 
     *  provide an empty constructor and r/w properties. */
    internal class PersistentStore
    {
        private var mName:String;
        private var mIndex:SharedObject;
        
        /** Create a persistent store with a certain name. If the name was already used in a 
         *  previous session, the existing store is restored. */
        public function PersistentStore(name:String)
        {
            mName = name;
            mIndex = SharedObjectPool.getObject(mName);
        }
        
        /** Saves an object with a certain key. If the key is already occupied, the previous
         *  object and its metadata are overwritten. */
        public function setObject(key:String, value:Object, metaData:Object=null):void
        {
            var info:Object = mIndex.data[key];
            var name:String = createUID();
            
            // If the object already exists we delete it and save 'value' under a new name.
            // This avoids problems if only one of the two SharedObjects can be saved.
            
            if (info && info.name)
                SharedObjectPool.clearObject(info.name);
            
            info = metaData ? cloneObject(metaData) : {};
            info.name = name;
            mIndex.data[key] = info;
            
            var sharedObject:SharedObject = SharedObjectPool.getObject(name);
            sharedObject.data.value = value;
        }
        
        /** Removes an object from the store. */
        public function removeObject(key:String):void
        {
            var info:Object = mIndex.data[key];
            if (info)
            {
                SharedObjectPool.getObject(info.name).clear();
                delete mIndex.data[key];
            }
        }
        
        /** Retrieves an object with a certain key, or null if it's not part of the store. */
        public function getObject(key:String):Object
        {
            var info:Object = mIndex.data[key];
            if (info) return SharedObjectPool.getObject(info.name).data.value;
            else      return null;
        }
        
        /** Indicates if an object with a certain key is part of the store. */
        public function containsKey(key:String):Boolean
        {
            return key in mIndex.data;
        }
        
        /** Store certain meta data with the object. Meta Data can be accessed without having
         *  to load the stored object from disk. Keep it small! */
        public function setMetaData(objectKey:String, metaDataName:String, metaDataValue:Object):void
        {
            var info:Object = mIndex.data[objectKey];
            if (info == null) throw new Error("object key not recognized");
            if (metaDataName == "name") throw new Error("'name' is reserved for internal use");
            info[metaDataName] = metaDataValue;
        }
        
        /** Retrieve specific meta data from a certain object. */
        public function getMetaData(objectKey:String, metaDataName:String):Object
        {
            var info:Object = mIndex.data[objectKey];
            if (info) return info[metaDataName];
            else      return null;
        }
        
        /** Removes all objects from the store, restoring all occupied disk storage. */
        public function clear():void
        {
            var key:String;
            var keys:Array = [];
            
            for (key in mIndex.data)
                keys.push(key);
            
            for each (key in keys)
            {
                var info:Object = mIndex.data[key];
                if (info && info.name)
                {
                    var so:SharedObject = SharedObjectPool.getObject(info.name);
                    if (so) so.clear();
                }
                delete mIndex.data[key];
            }
        }
        
        /** Saves the current state of the store to the disk. */
        public function flush():void
        {
            mIndex.flush();
        }
        
        /** Returns the name of the store as it was provided in the constructor. */
        public function get name():String { return mName; }
    }
}
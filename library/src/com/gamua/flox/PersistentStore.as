// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.utils.createUID;
    
    import flash.net.SharedObject;
    import flash.utils.Dictionary;

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
            mIndex = SharedObject.getLocal(mName);
            
            if (!("keys" in mIndex.data)) mIndex.data.keys = new Dictionary();
        }
        
        /** Saves an object with a certain key. If the key is already occupied, the previous
         *  object is overwritten. */
        public function addObject(key:String, value:Object):void
        {
            var name:String = mIndex.data.keys[key];
            if (name == null) 
            {
                name = createUID();
                mIndex.data.keys[key] = name;
            }
            
            var sharedObject:SharedObject = SharedObject.getLocal(name);
            sharedObject.data.value = value;
        }
        
        /** Removes an object from the store. */
        public function removeObject(key:String):void
        {
            var name:String = mIndex.data.keys[key];
            if (name)
            {
                delete mIndex.data.keys[key];
                SharedObject.getLocal(name).clear();
            }
        }
        
        /** Retrieves an object with a certain key, or null if it's not part of the store. */
        public function getObject(key:String):Object
        {
            var name:String = mIndex.data.keys[key];
            
            if (name == null) return null;
            else return SharedObject.getLocal(name).data.value;
        }
        
        /** Indicates if an object with a certain key is part of the store. */
        public function containsKey(key:String):Boolean
        {
            return key in mIndex.data.keys;
        }
        
        /** Removes all objects from the store, restoring all occupied disk storage. */
        public function clear():void
        {
            var keys:Dictionary = mIndex.data.keys;
            
            for each (var name:String in keys)
                SharedObject.getLocal(name).clear();
            
            mIndex.data.keys = new Dictionary();
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
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

    /** A queue that uses SharedObjects to save its contents to the disk. Objects are serialized
     *  using the AMF format, so be sure to use either primitive objects or classes to provide an
     *  empty constructor and r/w properties. */ 
    internal class PersistentQueue
    {
        private var mName:String;
        private var mIndex:SharedObject;
        
        private static var sLocks:Dictionary = new Dictionary();
        
        /** Create a persistent queue with a certain name. If the name was already used in a 
         *  previous session, the existing queue is restored. */ 
        public function PersistentQueue(name:String)
        {
            mName = name;
            mIndex = SharedObjectPool.getObject(mName);
            
            if (!("keys" in mIndex.data)) mIndex.data.keys = [];
            if (!(name in sLocks)) sLocks[name] = false;
        }
        
        /** Insert an object at the beginning of the queue. */
        public function enqueue(object:Object):void
        {
            var key:String = createUID();
            
            var sharedObject:SharedObject = SharedObjectPool.getObject(key);
            sharedObject.data.value = object;
            
            mIndex.data.keys.unshift(key);
        }
        
        /** Remove the object at the head of the queue. 
         *  If the queue is empty, this method returns null. */
        public function dequeue():Object
        {
            return getHead(true);
        }
        
        /** Returns the object at the head of the queue (without removing it).
         *  If the queue is empty, this method returns null. */
        public function peek():Object
        {
            return getHead(false);
        }
        
        /** Removes all elements from the queue. */
        public function clear():void
        {
            while (dequeue()) {};
        }
        
        /** Saves the current state of the queue to the disk. */
        public function flush():void
        {
            mIndex.flush();
        }
        
        private function getHead(removeHead:Boolean):Object
        {
            var keys:Array = mIndex.data.keys;
            if (keys.length == 0) return null;
            
            var key:String = keys[keys.length-1];
            var sharedObject:SharedObject = SharedObjectPool.getObject(key);
            var head:Object = sharedObject.data.value;
            
            if (head == null)
            {
                // shared object was deleted! remove object and try again
                keys.pop();
                head = getHead(removeHead);
            }
            else
            {
                if (removeHead)
                {
                    keys.pop();
                    sharedObject.clear();
                }
            }
            
            return head;
        }
        
        /** A flag indicating if modifying the queue is currently allowed. This does not actually
         *  prevent any modification: it's just a flag that is shared over all instances with
         *  the same name. */
        public function get isLocked():Boolean { return sLocks[name]; }
        public function set isLocked(value:Boolean):void { sLocks[name] = value; }
        
        /** Returns the number of elements in the queue. */
        public function get length():int { return mIndex.data.keys.length; }
        
        /** Returns the name of the queue as it was provided in the constructor. */
        public function get name():String { return mName; }
    }
}
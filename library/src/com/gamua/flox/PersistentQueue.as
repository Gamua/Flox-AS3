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

    internal class PersistentQueue
    {
        private var mName:String;
        private var mIndex:SharedObject;
        
        public function PersistentQueue(name:String)
        {
            mName = name;
            mIndex = SharedObject.getLocal(mName);
            
            if (!("keys" in mIndex.data)) mIndex.data.keys = [];
        }
        
        public function enqueue(object:Object):void
        {
            var key:String = createUID();
            
            var sharedObject:SharedObject = SharedObject.getLocal(key);
            sharedObject.data.value = object;
            
            mIndex.data.keys.unshift(key);
        }
        
        public function dequeue():Object
        {
            return getHead(true);
        }
        
        public function peek():Object
        {
            return getHead(false);
        }
        
        public function clear():void
        {
            while (dequeue()) {};
        }
        
        public function flush():void
        {
            mIndex.flush();
        }
        
        private function getHead(removeHead:Boolean):Object
        {
            var keys:Array = mIndex.data.keys;
            if (keys.length == 0) return null;
            
            var key:String = keys[keys.length-1];
            var sharedObject:SharedObject = SharedObject.getLocal(key);
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
        
        public function get length():int { return mIndex.data.keys.length; }
        public function get name():String { return mName; }
    }
}
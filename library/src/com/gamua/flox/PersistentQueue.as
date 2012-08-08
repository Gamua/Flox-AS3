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
        
        public function PersistentQueue(name:String)
        {
            mName = name;
        }
        
        public function enqueue(object:Object):void
        {
            var key:String = createUID();
            
            var sharedObject:SharedObject = SharedObject.getLocal(key);
            sharedObject.data.value = object;
            
            index.data.keys.unshift(key);
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
            index.flush();
        }
        
        private function getHead(removeHead:Boolean):Object
        {
            var keys:Array = index.data.keys;
            if (keys.length == 0) return null;
            
            var key:String = keys[keys.length-1];
            var sharedObject:SharedObject = SharedObject.getLocal(key);
            var head:Object = sharedObject.data.value;
            
            if (head == null)
            {
                // shared object was deleted! remove object and try again
                index.data.keys.pop();
                head = getHead(removeHead);
            }
            else
            {
                if (removeHead)
                {
                    index.data.keys.pop();
                    sharedObject.clear();
                }
            }
            
            return head;
        }
        
        private function get index():SharedObject
        {
            var sharedObject:SharedObject = SharedObject.getLocal(mName);
            if (!("keys" in sharedObject.data)) sharedObject.data.keys = [];
            return sharedObject;
        }
        
        public function get length():int { return index.data.keys.length; }
        public function get name():String { return mName; }
    }
}
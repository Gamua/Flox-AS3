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

    /** A queue that uses SharedObjects to save its contents to the disk. Objects are serialized
     *  using the AMF format, so be sure to use either primitive objects or classes to provide an
     *  empty constructor and r/w properties. */ 
    internal class PersistentQueue
    {
        private var mName:String;
        private var mIndex:SharedObject;
        
        /** Create a persistent queue with a certain name. If the name was already used in a 
         *  previous session, the existing queue is restored. */ 
        public function PersistentQueue(name:String)
        {
            mName = name;
            mIndex = SharedObjectPool.getObject(mName);
            
            if (!("elements" in mIndex.data)) mIndex.data.elements = [];
            
            if ("keys" in mIndex.data)
            {
                // migrate to new index system (can be removed in a future version)
                
                for each (var key:String in mIndex.data.keys)
                    mIndex.data.elements.push({ name: key, meta: null });
                    
                delete mIndex.data["keys"];
            }
        }
        
        /** Insert an object at the beginning of the queue.
         *  You can optionally add meta data that is stored in the index file. */
        public function enqueue(object:Object, metaData:Object=null):void
        {
            var name:String = createUID();
            
            var sharedObject:SharedObject = SharedObjectPool.getObject(name);
            sharedObject.data.value = object;
            
            mIndex.data.elements.unshift({ name: name, meta: metaData });
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
        
        /** Executes a callback for each queue element. If the callback returns 'false',
         *  the object will be removed from the queue. Callback definition:
         *  <pre>function(index:int, metaData:Object):Boolean;</pre> */
        public function filter(callback:Function):void
        {
            mIndex.data.elements = mIndex.data.elements.filter(
                function (element:Object, index:int, array:Array):Boolean
                {
                    var keep:Boolean = callback(index, element.meta);
                    if (!keep) SharedObjectPool.getObject(element.name).clear();
                    return keep;
                });
        }
        
        private function getHead(removeHead:Boolean):Object
        {
            var elements:Array = mIndex.data.elements;
            if (elements.length == 0) return null;
            
            var name:String = elements[elements.length-1].name;
            var sharedObject:SharedObject = SharedObjectPool.getObject(name);
            var head:Object = sharedObject.data.value;
            
            if (head == null)
            {
                // shared object was deleted! remove object and try again
                elements.pop();
                head = getHead(removeHead);
            }
            else
            {
                if (removeHead)
                {
                    elements.pop();
                    sharedObject.clear();
                }
            }
            
            return head;
        }
        
        /** Returns the number of elements in the queue. */
        public function get length():int { return mIndex.data.elements.length; }
        
        /** Returns the name of the queue as it was provided in the constructor. */
        public function get name():String { return mName; }
    }
}
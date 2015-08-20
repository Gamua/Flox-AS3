// =================================================================================================
//
//	Flox AS3
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import flash.net.SharedObject;
    import flash.utils.Dictionary;
    import flash.utils.clearInterval;
    import flash.utils.clearTimeout;
    import flash.utils.setInterval;

    /** This class keeps references to SharedObjects so that they are not garbage collected.
     *  All accessed shared objects will stay in memory for a custom time after being accessed.
     *  This (a) makes accessing them much faster, which is especially important for the
     *  'PersistentQueue', and (b) avoids a bug in the Flash Player that happens when two 
     *  flush operations are happening simultaneously (one initiated through the GC, the other
     *  manually). */ 
    internal class SharedObjectPool
    {
        private static var sIntervalID:uint = uint.MAX_VALUE;
        private static var sPool:Dictionary = new Dictionary();
        private static var sPoolNames:Vector.<String> = new <String>[];
        private static var sAccessedNames:Dictionary = new Dictionary();
        
        public function SharedObjectPool()
        {
            throw new Error("This class cannot be instantiated.");
        }
        
        public static function startAutoCleanup(interval:Number=20):void
        {
            clearInterval(sIntervalID);
            sIntervalID = setInterval(clearUnusedObjects, interval * 1000);
        }
        
        public static function stopAutoCleanup():void
        {
            clearInterval(sIntervalID);
        }
        
        private static function clearUnusedObjects():void
        {
            for (var name:String in sPool)
                sPoolNames[sPoolNames.length] = name;
            
            for each (name in sPoolNames)
                if (!(name in sAccessedNames))
                    delete sPool[name];
            
            sPoolNames.length = 0;
            sAccessedNames = new Dictionary();
        }
        
        public static function getObject(name:String):SharedObject
        {
            var so:SharedObject = sPool[name];
            
            if (so == null)
            {
                so = SharedObject.getLocal(name);
                sPool[name] = so;
            }
            
            sAccessedNames[name] = true;
            return so;
        }
        
        public static function clearObject(name:String):void
        {
            var so:SharedObject = getObject(name);
            so.clear();
            
            delete sPool[name];
        }
        
        public static function purgePool():void
        {
            sPool = new Dictionary();
        }
        
        public static function flush():void
        {
            for each (var so:SharedObject in sPool)
                so.flush();
        }
        
        public static function contains(name:String):Boolean { return name in sPool; }
    }
}
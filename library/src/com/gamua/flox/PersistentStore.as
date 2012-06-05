package com.gamua.flox
{
    import flash.net.SharedObject;

    internal class PersistentStore
    {
        private static var sData:Object = {};
        
        public function PersistentStore() { throw new Error("This class cannot be instantiated."); }
        
        public static function flush():void
        {
            try { sharedObject.flush(); }
            catch (e:Error) {}
        }
        
        public static function get(key:String):Object
        {
            return data[key];
        }
        
        public static function set(key:String, value:Object):void
        {
            data[key] = value;
        }
        
        private static function get data():Object
        {
            try { sData = sharedObject.data; }
            catch (e:Error) { }
            
            return sData;
        }
        
        private static function get sharedObject():SharedObject
        {
            return SharedObject.getLocal("Flox");
        }
    }
}
package com.gamua.flox.utils
{
    import com.gamua.flox.Entity;
    
    public class CustomEntity extends Entity
    {
        public static const TYPE:String = "custom";
        
        private var mName:String;
        private var mAge:int;
        private var mData:Object;
        
        public function CustomEntity(name:String="unknown", age:int=0)
        {
            super(TYPE);
            
            mName = name;
            mAge = age;
            mData = { value: int(Math.random() * 1000) };
        }
        
        public function get name():String { return mName; }
        public function set name(value:String):void { mName = value; }
        
        public function get age():int { return mAge; }
        public function set age(value:int):void { mAge = value; }
        
        public function get data():Object { return mData; }
        public function set data(value:Object):void { mData = value; }
        
    }
}
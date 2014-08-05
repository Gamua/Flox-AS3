package com.gamua.flox.utils
{
    import com.gamua.flox.Entity;
    
    public class CustomEntity extends Entity
    {
        private var mName:String;
        private var mAge:int;
        private var mData:Object;
        private var mBirthday:Date;
        
        public var publicMember:String;
        
        public function CustomEntity(name:String="unknown", age:int=0)
        {
            mName = name;
            mAge = age;
            mData = { value: int(Math.random() * 1000) };
            mBirthday = new Date();
            publicMember = "undefined";
        }
        
        protected override function onConflict(remoteEntity:Entity):void
        {
            var that:CustomEntity = remoteEntity as CustomEntity;
            this.age = Math.max(this.age, that.age);
        }
        
        public function get name():String { return mName; }
        public function set name(value:String):void { mName = value; }
        
        public function get age():int { return mAge; }
        public function set age(value:int):void { mAge = value; }
        
        public function get data():Object { return mData; }
        public function set data(value:Object):void { mData = value; }
        
        public function get birthday():Date { return mBirthday; }
        public function set birthday(value:Date):void { mBirthday = value; }
    }
}
package com.gamua.flox
{
    import com.gamua.flox.utils.DateUtil;

    public class Score
    {
        private var mValue:int;
        private var mPlayerName:String;
        private var mPlayerID:String;
        private var mCountry:String;
        private var mTime:Date;
        
        public function Score(playerID:String, playerName:String, value:int, 
                              time:Date, country:String)
        {
            mPlayerID = playerID;
            mPlayerName = playerName;
            mValue = value;
            mTime = new Date(time.time);
            mCountry = country;
        }
        
        public function toXml():XML
        {
            return <score playerID={mPlayerID} playerName={mPlayerName} value={mValue} 
                          time={DateUtil.toW3CDTF(mTime)} country={mCountry} />
        }
        
        public static function fromXml(xml:XML):Score
        {
            return new Score(xml.@playerId.toString(), xml.@playerName.toString(), 
                             parseInt(xml.@value.toString()), 
                             DateUtil.parseW3CDTF(xml.@time.toString()), "us");
        }
        
        public function get value():int { return mValue; }
        public function get playerName():String { return mPlayerName; }
        public function get playerID():String { return mPlayerID; }
        public function get time():Date { return mTime; }
        public function get country():String { return mCountry; }
    }
}
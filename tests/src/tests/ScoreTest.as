package tests
{
    import com.gamua.flox.Score;
    import com.gamua.flox.utils.XmlConvert;
    
    import starling.unit.UnitTest;

    public class ScoreTest extends UnitTest
    {
        public function testProperties():void
        {
            var playerID:String = "hugoID";
            var playerName:String = "hugoName";
            var value:int = 1234;
            var time:Date = new Date();
            var country:String = "at";
            
            var score:Score = new Score(playerID, playerName, value, time, country);
            
            assertEqual(playerID, score.playerID);
            assertEqual(playerName, score.playerName);
            assertEqual(value, score.value);
            assertEqual(time.time, score.time.time);
            assertEqual(country, score.country);
        }
        
        public function testFromXml():void
        {
            var playerID:String = "hugoID";
            var playerName:String = "hugoName";
            var value:int = 1234;
            var time:Date = new Date();
            
            var xml:XML = <score playerId={playerID} playerName={playerName} value={value}
                                 time={XmlConvert.dateToString(time)}/>;
            
            var score:Score = Score.fromXml(xml);
            assertEqual(playerID, score.playerID);
            assertEqual(playerName, score.playerName);
            assertEqual(value, score.value);
            assertEquivalent(time.time, score.time.time, "Time differs", 100);
        }
        
        public function testToXml():void
        {
            var playerID:String = "hugoID";
            var playerName:String = "hugoName";
            var value:int = 1234;
            var time:Date = new Date();
            var country:String = "at";
            
            var score:Score = new Score(playerID, playerName, value, time, country);
            var xml:XML = score.toXml();
            
            assertEqual(xml.@playerID.toString(), playerID);
            assertEqual(xml.@playerName.toString(), playerName);
            assertEqual(xml.@value.toString(), value);
            assertEqual(xml.@time.toString(), XmlConvert.dateToString(time));
            assertEqual(xml.@country.toString(), country);
        }
    }
}
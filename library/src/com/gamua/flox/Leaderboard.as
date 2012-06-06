package com.gamua.flox
{
    import com.gamua.flox.utils.createURL;

    public class Leaderboard
    {
        private static const DEFAULT_COUNT:int = 50;
        
        private var mID:String;
        private var mTimeScope:String;
        private var mSortOrder:String;
        private var mScores:Vector.<Score>;
        
        public function Leaderboard(id:String="unknown", sortOrder:String=null)
        {
            mID = id;
            mTimeScope = TimeScope.ALL_TIME;
            mSortOrder = sortOrder? sortOrder : SortOrder.HIGH_TO_LOW;
            mScores = new <Score>[];
        }
        
        public static function fromXml(xml:XML):Leaderboard
        {
            var leaderboard:Leaderboard = 
                new Leaderboard(xml.@leaderboardId.toString(), xml.@sortOrder.toString());
            leaderboard.mTimeScope = xml.@timeScope.toString();
            
            var scores:Array = [];
            for each (var scoreXml:XML in xml.score)
                scores.push(Score.fromXml(scoreXml));
            
            leaderboard.addScores(scores);
            return leaderboard;
        }
        
        public function get id():String { return mID; }
        public function get timeScope():String { return mTimeScope; }
        public function get sortOrder():String { return mSortOrder; }
        public function get length():int { return mScores.length; }
        
        public function get localizedName():String
        {
            return Flox.localize(mID);
        }
        
        public function addScores(...scores):void
        {
            if (scores.length == 1 && scores[0] is Array) scores = scores[0];
            
            for each (var score:Score in scores)
                mScores.push(score);
            
            sortScores();
        }
        
        public function getScoreAt(rank:int):Score
        {
            if (rank < 0 || rank >= length) 
                throw new RangeError("Invalid rank. (Ranks start at zero!)");
            
            return mScores[rank];
        }
        
        private function sortScores():void
        {
            mScores.sort(mSortOrder == SortOrder.HIGH_TO_LOW ? sortHTL : sortLTH);
            
            function sortHTL(a:Score, b:Score):int
            {
                if (a.value > b.value) return -1;
                else if (a.value < b.value) return 1;
                else return 0;
            }
            
            function sortLTH(a:Score, b:Score):int
            {
                return sortHTL(a, b) * -1;
            }
        }
        
        internal static function load(gameID:String, leaderboardID:String, timeScope:String,
                                      onComplete:Function=null, onError:Function=null):void
        {
            var url:String = createUrl(gameID, leaderboardID, timeScope + ".xml");
            HttpManager.getXml(url, {"count": DEFAULT_COUNT}, onGetComplete, onError);
            
            function onGetComplete(leaderboardXml:XML):void
            {
                onComplete(fromXml(leaderboardXml));
            }
        }
        
        internal static function postScore(gameID:String, leaderboardID:String, score:int, 
                                           playerID:String, playerName:String, gameKey:String):void
        {
            var url:String = createUrl(gameID, leaderboardID);
            var params:Object = { "playerId": playerID, "playerName": playerName, "value": score }; 
            HttpManager.postQueued(url, params, gameKey); 
        }
        
        internal static function createUrl(gameID:String, leaderboardID:String, ...rest):String
        {
            rest.unshift("games", gameID, "leaderboards", leaderboardID, "scores");
            return createURL(rest);
        }
    }
}
// =================================================================================================
//
//	Flox AS3
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.utils.DateUtil;
    import com.gamua.flox.utils.HttpMethod;
    
    import flash.system.Capabilities;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;

    /** A Game Session contains the Analytics data of one game. */
    internal class GameSession
    {
        private var mGameVersion:String;
        private var mStartTime:Date;
        private var mDuration:int;
        private var mLog:Array;
        private var mNumErrors:int;
        private var mIntervalID:uint;
        
        /** Do not call this constructor directly, but create sessions via the static 
         *  'start' method instead. */
        public function GameSession(gameVersion:String="1.0")
        {
            mGameVersion = gameVersion;
            mStartTime = new Date();
            mDuration = 0;
            mLog = [];
            mNumErrors = 0;
            mIntervalID = 0;
        }
        
        /** Starts a new session and closes the previous one. This will send the analytics of 
         *  both sessions to the server (including log entries of the last session). 
         *  @returns the new GameSession. */
        public static function start(gameID:String, gameVersion:String,
                                     lastSession:GameSession=null, 
                                     reportAnalytics:Boolean=true):GameSession
        {
            var newSession:GameSession = new GameSession(gameVersion);
            var resolution:String = Capabilities.screenResolutionX + "x" + 
                                    Capabilities.screenResolutionY;
            
            var data:Object = {
                startTime: DateUtil.toString(newSession.mStartTime),
                gameVersion: gameVersion,
                languageCode: Capabilities.language,
                deviceInfo: {
                    resolution: resolution,
                    os: Capabilities.os,
                    flashPlayerType:    Capabilities.playerType,
                    flashPlayerVersion: Capabilities.version
                }
            };
            
            if (lastSession)
            {
                lastSession.pause();
                data.lastStartTime = DateUtil.toString(lastSession.startTime);
                data.lastDuration  = lastSession.duration;
                data.lastLog = lastSession.log;
            }
            
            if (reportAnalytics)
                Flox.service.requestQueued(HttpMethod.POST, ".analytics", data);
            
            newSession.start();
            return newSession;
        }
        
        /** (Re)starts the timer reporting the duration of a session. This is done automatically
         *  by the static 'start' method as well. */
        public function start():void
        {
            if (mIntervalID == 0) 
                mIntervalID = setInterval(function():void { ++mDuration }, 1000);
        }
        
        /** Stops the timer that reports the duration of a session. */
        public function pause():void
        {
            clearInterval(mIntervalID);
            mIntervalID = 0;
        }
        
        // logging
        
        /** Adds a log of type 'info'. */
        public function logInfo(message:String):void
        {
            addLogEntry("info", { message: message });
        }
        
        /** Adds a log of type 'warning'. */
        public function logWarning(message:String):void
        {
            addLogEntry("warning", { message: message });
        }
        
        /** Adds a log of type 'error'. */
        public function logError(name:String, message:String=null, stacktrace:String=null):void
        {
            addLogEntry("error", { name: name, message: message, stacktrace: stacktrace });
            mNumErrors++;
        }
        
        /** Adds a log of type 'event', with an optional dictionary of additional data. */
        public function logEvent(name:String, properties:Object=null):void
        {
            var entry:Object = { name: name };
            if (properties !== null) entry.properties = properties;
            addLogEntry("event", entry);
        }
        
        private function addLogEntry(type:String, entry:Object):void
        {
            entry.type = type;
            entry.time = DateUtil.toString(new Date());
            mLog.push(entry);
        }
        
        // properties 
        // since this class is saved in a SharedObject, everything has to be R/W!
        
        /** The version of the game as it was passed to the 'start' method. */
        public function get gameVersion():String { return mGameVersion; }
        public function set gameVersion(value:String):void { mGameVersion = value; }
        
        /** The exact time the session was started. */
        public function get startTime():Date { return mStartTime; }
        public function set startTime(value:Date):void { mStartTime = value; }
        
        /** The duration of the session in seconds. */
        public function get duration():int { return mDuration; }
        public function set duration(value:int):void { mDuration = value; }
        
        /** An array of all log entries in chronological order. */
        public function get log():Array { return mLog; }
        public function set log(value:Array):void { mLog = value; }
        
        /** The number of reported erros (via the 'logError' method). */
        public function get numErrors():int { return mNumErrors; }
        public function set numErrors(value:int):void { mNumErrors = value; }
    }
}
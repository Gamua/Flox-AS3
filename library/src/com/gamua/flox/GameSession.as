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
    
    import flash.net.SharedObject;
    import flash.net.registerClassAlias;
    import flash.system.Capabilities;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;

    internal class GameSession
    {
        private var mGameVersion:String;
        private var mStartTime:Date;
        private var mDuration:int;
        private var mLog:Array;
        private var mNumErrors:int;
        private var mIntervalID:uint;
        
        private static var sCurrentSession:SharedObject;
        
        public function GameSession(gameVersion:String="1.0")
        {
            registerClasses();
            
            mGameVersion = gameVersion;
            mStartTime = new Date();
            mDuration = 0;
            mLog = [];
            mNumErrors = 0;
            mIntervalID = 0;
        }
        
        public static function start(restService:IRestService, gameVersion:String="1.0"):GameSession
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
            
            sCurrentSession = SharedObject.getLocal("Flox.GameSession.current");
            
            if (sCurrentSession)
            {
                var oldSession:GameSession = sCurrentSession.data.value;
                if (oldSession)
                {
                    oldSession.pause();
                    data.lastStartTime = DateUtil.toString(oldSession.startTime);
                    data.lastDuration  = oldSession.duration;
                    data.lastLog = oldSession.log;
                    sCurrentSession.clear();
                }
            }
            
            restService.requestQueued(HttpMethod.POST, ".analytics", data);
            
            sCurrentSession.data.value = newSession;
            newSession.start();
            
            return newSession;
        }
        
        public function start():void
        {
            if (mIntervalID == 0) 
                mIntervalID = setInterval(function():void { ++mDuration }, 1000);
        }
        
        public function pause():void
        {
            clearInterval(mIntervalID);
            mIntervalID = 0;
        }
        
        public function save():void
        {
            sCurrentSession.flush();
        }
        
        // logging
        
        public function logInfo(message:String):void
        {
            addLogEntry("info", message);
        }
        
        public function logWarning(message:String):void
        {
            addLogEntry("warning", message);
        }
        
        public function logError(message:String):void
        {
            addLogEntry("error", message);
            mNumErrors++;
        }
        
        public function logEvent(name:String):void
        {
            addLogEntry("event", name);
        }
        
        private function addLogEntry(type:String, message:String):void
        {
            mLog.push(new LogEntry(type, message));
        }
        
        // persistence
        
        private static function registerClasses():void
        {
            registerClassAlias("LogEntry", LogEntry);
            registerClassAlias("GameSession", GameSession);
        }
        
        // properties 
        // since this class is saved in a SharedObject, everything has to be R/W!
        
        public function get gameVersion():String { return mGameVersion; }
        public function set gameVersion(value:String):void { mGameVersion = value; }
        
        public function get startTime():Date { return mStartTime; }
        public function set startTime(value:Date):void { mStartTime = value; }
        
        public function get duration():int { return mDuration; }
        public function set duration(value:int):void { mDuration = value; }
        
        public function get log():Array { return mLog; }
        public function set log(value:Array):void { mLog = value; }
        
        public function get numErrors():int { return mNumErrors; }
        public function set numErrors(value:int):void { mNumErrors = value; }
    }
}

import com.gamua.flox.utils.DateUtil;

// internal class
class LogEntry
{
    public var type:String;
    public var message:String;
    public var time:String;
    
    public function LogEntry(type:String="info", message:String="", time:Date=null)
    {
        if (time == null) time = new Date();
        
        this.type = type;
        this.message = message;
        this.time = DateUtil.toString(time);
    }
}

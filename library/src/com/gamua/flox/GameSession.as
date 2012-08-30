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

    public class Analytics
    {
        public function Analytics() { throw new Error("This class cannot be instantiated."); }
        
        public static function startSession(version:String):void
        {
            endSession();
            
            // TODO: in AIR, listen for ACTIVATE/DEACTIVATE to get duration
            
            var lastStartTime:Date  = cache.data.startTime;
            var lastDuration:Number = cache.data.duration;
            
            var startTime:Date = cache.data.startTime = new Date();
            var resolution:String = Capabilities.screenResolutionX + "x" + Capabilities.screenResolutionY;
            
            var data:Object = {
                startTime: DateUtil.toString(startTime),
                gameVersion: version,
                languageCode: Capabilities.language,
                deviceInfo: {
                    resolution: resolution,
                    os: Capabilities.os,
                    flashPlayerType: Capabilities.playerType,
                    flashPlayerVersion: Capabilities.version
                }
            };
            
            if (lastDuration)
            {
                data.lastStartTime = DateUtil.toString(lastStartTime);
                data.lastDuration  = lastDuration;
                data.lastLog = cache.data.log;
            }
            
            cache.data.log = [];
            cache.data.errorCount = 0;
            cache.data.duration = -1;
            cache.data.sessionStarted = true;
            
            Flox.requestQueued(HttpMethod.POST, ".analytics", data);
        }
        
        public static function endSession():void
        {
            registerClasses();
            
            var sessionStarted:Boolean = cache.data.sessionStarted;
            var startTime:Date = cache.data.startTime;
            
            if (sessionStarted && startTime)
            {
                cache.data.sessionStarted = false;
                cache.data.duration = (new Date().time - startTime.time) / 1000;
                
                // the complete loggings are only submitted if there was an error.
                // otherwise, only the events are sent to the server.
                
                if (cache.data.errorCount == 0)
                {
                    var eventsOnly:Array = [];
                    
                    for each (var logEntry:LogEntry in cache.data.log)
                        if (logEntry.type == "event")
                            eventsOnly.push(logEntry);
                    
                    cache.data.log = eventsOnly;
                }
            }
        }
        
        // logging
        
        public static function logInfo(message:String):void
        {
            addLogEntry("info", message);
        }
        
        public static function logWarning(message:String):void
        {
            addLogEntry("warning", message);
        }
        
        public static function logError(message:String):void
        {
            addLogEntry("error", message);
            cache.data.errorCount++;
        }
        
        public static function logEvent(name:String):void
        {
            addLogEntry("event", name);
        }
        
        private static function addLogEntry(type:String, message:String):void
        {
            cache.data.log.push(new LogEntry(type, message));
        }
        
        private static function registerClasses():void
        {
            registerClassAlias("LogEntry", LogEntry);
        }
        
        // persistent data
        
        private static function get cache():SharedObject
        {
            return SharedObject.getLocal("Flox.Analytics.cache");
        }
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

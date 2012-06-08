package com.gamua.flox
{
    import com.gamua.flox.utils.DateUtil;
    import com.gamua.flox.utils.createUID;
    import com.gamua.flox.utils.createURL;
    import com.gamua.flox.utils.encodeXml;
    import com.gamua.flox.utils.registerClass;
    
    import flash.system.Capabilities;

    public class Analytics
    {
        public function Analytics() { throw new Error("This class cannot be instantiated."); }
        
        public static function startSession(gameID:String, gameKey:String, gameVersion:String):void
        {
            registerClass(LogEntry);
            endSession(gameID, gameKey);
            
            sessionID = createUID();
            logEntries = new <LogEntry>[];            
            
            var startTime:Date = new Date();
            var resolution:String = Capabilities.screenResolutionX + "x" + Capabilities.screenResolutionY;
            var startXml:XML = 
                    <analyticsSessionStart>
                      <sessionId>{sessionID}</sessionId>
                      <startTime>{DateUtil.toW3CDTF(startTime, true)}</startTime>
                      <gameVersion>{gameVersion}</gameVersion>
                      <languageCode>{Capabilities.language}</languageCode>
                      <deviceInfo>
                        <resolution>{resolution}</resolution>
                        <os>{Capabilities.os}</os>
                        <flashPlayerType>{Capabilities.playerType}</flashPlayerType>
                        <flashPlayerVersion>{Capabilities.version}</flashPlayerVersion>
                      </deviceInfo>
                    </analyticsSessionStart>;
            
            if (lastStartTime) 
                startXml.lastStartTime = DateUtil.toW3CDTF(lastStartTime, true);
            
            lastStartTime = startTime;
            
            HttpManager.postQueued(createURL("games", gameID, "analytics", "startSession"),
                { data: encodeXml(startXml), dataEncoding: "zlib" }, gameKey);
        }
        
        public static function endSession(gameID:String, gameKey:String):void
        {
            if (sessionID == null) return;
            
            var endTime:Date = new Date();
            var duration:Number = (endTime.time - lastStartTime.time) / 1000;
            
            var endXml:XML = 
                <analyticsSessionEnd>
                  <sessionId>{sessionID}</sessionId>
                  <startTime>{DateUtil.toW3CDTF(lastStartTime)}</startTime>
                  <duration>{duration}</duration>
                  <log/>
                </analyticsSessionEnd>;
            
            for each (var logEntry:LogEntry in logEntries)
                endXml.log.appendChild(logEntry.toXml());
            
            HttpManager.postQueued(createURL("games", gameID, "analytics", "endSession"),
                { data: encodeXml(endXml), dataEncoding: "zlib" }, gameKey);
            
            sessionID = null;
            logEntries = null;
        }
        
        // logging
        
        public static function logInfo(message:String):void
        {
            logEntries.push(LogEntry.info(message));
        }
        
        public static function logWarning(message:String):void
        {
            logEntries.push(LogEntry.warning(message));
        }
        
        public static function logError(message:String):void
        {
            logEntries.push(LogEntry.error(message));
        }
        
        public static function logEvent(name:String):void
        {
            logEntries.push(LogEntry.event(name));
        }
        
        // Persistant Store Access
        
        private static function get lastStartTime():Date
        {
            return PersistentStore.get("Analytics.lastStartTime") as Date;
        }
        
        private static function set lastStartTime(value:Date):void
        {
            PersistentStore.set("Analytics.lastStartTime", value);
        }
        
        private static function get sessionID():String
        {
            return PersistentStore.get("Analytics.sessionID") as String;
        }
        
        private static function set sessionID(value:String):void
        {
            PersistentStore.set("Analytics.sessionID", value);
        }
        
        private static function get logEntries():Vector.<LogEntry>
        {
            return PersistentStore.get("Analytics.logEntries") as Vector.<LogEntry>;
        }
        
        private static function set logEntries(value:Vector.<LogEntry>):void
        {
            PersistentStore.set("Analytics.logEntries", value);
        }
    }
}

import flash.utils.getTimer;

class LogEntry
{
    public var type:String;
    public var time:Number;
    public var message:String;
    
    public function LogEntry(type:String=null, message:String=null, time:Number=0)
    {
        this.type = type;
        this.message = message;
        this.time = time;
    }
    
    public function toXml():XML
    {
        return <LogEntry>
                 <type>{type}</type>
                 <time>{time}</time>
                 <message>{message}</message>
               </LogEntry>;
    }
    
    public static function info(message:String):LogEntry
    {
        return new LogEntry("info", message, getTimer() / 1000);
    }
    
    public static function warning(message:String):LogEntry
    {
        return new LogEntry("warning", message, getTimer() / 1000);
    }
    
    public static function error(message:String):LogEntry
    {
        return new LogEntry("error", message, getTimer() / 1000);
    }
    
    public static function event(message:String):LogEntry
    {
        return new LogEntry("event", message, getTimer() / 1000);
    }
}
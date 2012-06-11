package com.gamua.flox
{
    import com.gamua.flox.utils.XmlConvert;
    import com.gamua.flox.utils.createUID;
    import com.gamua.flox.utils.createURL;
    
    import flash.system.Capabilities;

    public class Analytics
    {
        public function Analytics() { throw new Error("This class cannot be instantiated."); }
        
        public static function startSession(gameID:String, gameKey:String, gameVersion:String):void
        {
            PersistentStore.registerClass(LogEntry);
            endSession(gameID, gameKey);
            
            sessionID = createUID();
            logEntries = new <LogEntry>[];            
            
            var startTime:Date = new Date();
            var resolution:String = Capabilities.screenResolutionX + "x" + Capabilities.screenResolutionY;
            var startXml:XML = 
                    <analyticsSessionStart>
                      <sessionId>{sessionID}</sessionId>
                      <startTime>{XmlConvert.dateToString(startTime)}</startTime>
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
                startXml.lastStartTime = XmlConvert.dateToString(lastStartTime);
            
            lastStartTime = startTime;
            
            HttpManager.postQueued(createURL("games", gameID, "analytics", "startSession"),
                { data: XmlConvert.encode(startXml), dataCompression: "zlib" }, gameKey);
        }
        
        public static function endSession(gameID:String, gameKey:String):void
        {
            if (sessionID == null) return;
            
            var endTime:Date = new Date();
            var duration:Number = (endTime.time - lastStartTime.time) / 1000;
            
            var endXml:XML = 
                <analyticsSessionEnd>
                  <sessionId>{sessionID}</sessionId>
                  <startTime>{XmlConvert.dateToString(lastStartTime)}</startTime>
                  <duration>{duration}</duration>
                  <log/>
                </analyticsSessionEnd>;
            
            for each (var logEntry:LogEntry in logEntries)
                endXml.log.appendChild(logEntry.toXml());
            
            HttpManager.postQueued(createURL("games", gameID, "analytics", "endSession"),
                { data: XmlConvert.encode(endXml), dataCompression: "zlib" }, gameKey);
            
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

import com.gamua.flox.utils.XmlConvert;

import flash.utils.getTimer;

class LogEntry
{
    public var type:String;
    public var time:Date;
    public var message:String;
    
    public function LogEntry(type:String=null, message:String=null, time:Date=null)
    {
        this.type = type;
        this.message = message;
        this.time = time;
    }
    
    public function toXml():XML
    {
        return <logEntry>
                 <type>{type}</type>
                 <time>{XmlConvert.dateToString(time)}</time>
                 <message>{message}</message>
               </logEntry>;
    }
    
    public static function info(message:String):LogEntry
    {
        return new LogEntry("info", message, new Date());
    }
    
    public static function warning(message:String):LogEntry
    {
        return new LogEntry("warning", message, new Date());
    }
    
    public static function error(message:String):LogEntry
    {
        return new LogEntry("error", message, new Date());
    }
    
    public static function event(message:String):LogEntry
    {
        return new LogEntry("event", message, new Date());
    }
}
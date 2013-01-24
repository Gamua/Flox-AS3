// =================================================================================================
//
//	Flox AS3
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox.events
{
    import com.gamua.flox.utils.HttpStatus;
    
    import flash.events.Event;
    
    /** An Event that is dispatched when Flox has processed the request queue. The event contains 
     *  information about the outcome of the queue processing - i.e. the http status and
     *  (in case of an error) error message of the last processed request. */
    public class QueueEvent extends Event
    {
        /** The type of the event that is dispatched when the request queue finished processing. */ 
        public static const QUEUE_PROCESSED:String = "queueProcessed";
        
        private var mError:String;
        private var mHttpStatus:int;
        
        /** Creates a new QueueEvent with the specified 'success' value. */
        public function QueueEvent(type:String, httpStatus:int=200, error:String="")
        {
            super(type);
            mError = error;
            mHttpStatus = httpStatus;
        }
        
        /** This property indicates if all queue elements were processed: if it's true, the queue
         *  is now empty. */
        public function get success():Boolean 
        {
            return HttpStatus.isSuccess(mHttpStatus) || !HttpStatus.isTransientError(mHttpStatus);
        }
        
        /** If unsuccessful, contains the error message that caused queue processing to stop. */ 
        public function get error():String { return mError; }
        
        /** Contains the http status of the last processed queue element. The queue will stop
         *  processing either when it's empty, or when there is a transient error. */
        public function get httpStatus():int { return mHttpStatus; }
    }
}
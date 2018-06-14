// =================================================================================================
//
//	Flox AS3
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
// =================================================================================================

package com.gamua.flox
{
    import com.gamua.flox.events.QueueEvent;
    import com.gamua.flox.utils.DateUtil;
    import com.gamua.flox.utils.HttpMethod;
    import com.gamua.flox.utils.HttpStatus;
    import com.gamua.flox.utils.cloneObject;
    import com.gamua.flox.utils.createUID;
    import com.gamua.flox.utils.createURL;
    import com.gamua.flox.utils.describeType;
    import com.gamua.flox.utils.execute;
    import com.gamua.flox.utils.formatString;
    
    import flash.system.Capabilities;
    import flash.utils.Dictionary;
    import flash.utils.getQualifiedClassName;
    
    /** The (abstract) base class of all objects that can be stored persistently on the Flox server.
     *  
     *  <p>To create custom entities, extend this class. Subclasses have to follow a few rules:</p>
     * 
     *  <ul>
     *   <li>All constructor arguments must have default values.</li>
     *   <li>Properties always need to be readable and writable.</li>
     *   <li>Properties may have one of the following types:
     *       <code>int, Number, Boolean, String, Object, Array, Date.</code>
     *       Support for nested entities or complex data types may be added at a later time.</li>
     *   <li>The server type of the class is defined by its name. If you want to use a different
     *       name, you can provide "Type" MetaData (see sample below).</li>
     *   <li>To prevent serialization of a certain property, you can mark it with "NonSerialized" 
     *       MetaData (see sample below).</li> 
     *  </ul>
     *  
     *  <p>Here is an example class:</p>
     *  
     *  <pre>
     *  [Type("gameState")] // optional server type; defaults to class name.
     *  public class GameState extends Entity
     *  {
     *      private var _level:int;
     *      private var _score:int;
     *      
     *      public function GameState(level:int=0, score:int=0)
     *      {
     *          _level = level;
     *          _score = score;
     *      }
     *      
     *      public function get level():int { return _level; }
     *      public function set level(value:int):void { _level = value; }
     *      
     *      public function get score():int { return _score; }
     *      public function set score(value:int):void { _score = value; }
     * 
     *      [NonSerialized] // optional: prevent serialization of this property
     *      public function get internalState:Object { ... }
     *      public function set internalState(value:Object):void { ... }
     *  }</pre>
     *  
     */
    public class Entity
    {
        private var mId:String;
        private var mCreatedAt:Date;
        private var mUpdatedAt:Date;
        private var mOwnerId:String;
        private var mPublicAccess:String;
        
        private static const sTypeCache:Dictionary = new Dictionary();

        /** Abstract class constructor. Call this via 'super' from your subclass, passing your
         *  custom type string. */
        public function Entity()
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "com.gamua.flox::Entity")
            {
                throw new Error("Abstract class -- do not instantiate");
            }
            
            mId = createUID();
            mCreatedAt = new Date();
            mUpdatedAt = new Date();
            mOwnerId = Flox.currentPlayer ? Flox.currentPlayer.id : null; 
            mPublicAccess = "";
        }
        
        /** Returns a description of the entity, containing its basic information. */
        public function toString():String
        {
            return formatString(
                '[Entity type="{0}" id="{1}" createdAt="{2}" updatedAt="{3}" ownerId="{4}"]',
                type, mId, DateUtil.toString(mCreatedAt), DateUtil.toString(mUpdatedAt), mOwnerId);
        }
        
        /** Saves the entity on the server; if the entity already exists, the server version will
         *  be updated with the local changes. It is guaranteed that one (and only one) of the 
         *  provided callbacks will be executed; all callback arguments are optional.
         * 
         *  <p>In case of an error, use the method 'HttpStatus.isTransientError(httpStatus)'
         *  to find out if the error is just temporary (e.g. the server was not reachable).</p> 
         *  
         *  @param onComplete  executed when the operation is successful; function signature:
         *                     <pre>onComplete(entity:Entity):void;</pre>
         *  @param onError     executed when the operation was not successful; function signature:
         *                     <pre>onError(error:String, httpStatus:int):void;</pre>         
         */
        public function save(onComplete:Function, onError:Function):void
        {
            Entity.save(this, onComplete, onError);
        }
        
        /** Saves the entity the next time the player goes online. When the Flox server cannot be
         *  reached at the moment, the request will be added to a queue and will be repeated
         *  later. */
        public function saveQueued():void
        {
            Entity.saveQueued(this);
        }
        
        /** Refreshes the entity with the version that is currently stored on the server.
         *  It is guaranteed that one (and only one) of the provided callbacks will be executed;
         *  all callback arguments are optional.
         * 
         *  <p>In case of an error, use the method 'HttpStatus.isTransientError(httpStatus)'
         *  to find out if it's just temporary (e.g. the server was not reachable).</p>
         *  
         *  @param onComplete  executed when the operation is successful; function signature:
         *                     <pre>onComplete(entity:Entity):void;</pre>
         *  @param onError     executed when the operation was not successful; function signature:
         *                     <pre>onError(error:String, httpStatus:int):void;</pre>         
         */
        public function refresh(onComplete:Function, onError:Function):void
        {
            Entity.refresh(this, onComplete, onError);
        }
        
        /** Deletes the entity from the server. It is guaranteed that one (and only one) of the 
         *  provided callbacks will be executed; all callback arguments are optional.
         * 
         *  <p>In case of an error, use the method 'HttpStatus.isTransientError(httpStatus)' 
         *  to find out if the error is just temporary (e.g. the server was not reachable).</p> 
         *  
         *  @param onComplete   executed when the operation is successful; function signature:
         *                      <pre>onComplete(entity:Entity):void;</pre>
         *  @param onError      executed when the operation was not successful; function signature:
         *                      <pre>onError(error:String, httpStatus:int):void;</pre>         
         */
        public function destroy(onComplete:Function, onError:Function):void
        {
            var self:Entity = this;
            Entity.destroy(getClass(this), mId, onDestroyComplete, onError);
            
            function onDestroyComplete():void
            {
                execute(onComplete, self);
            }
        }
        
        /** Deletes the entity the next time the player goes online. When the Flox server cannot be
         *  reached at the moment, the request will be added to a queue and will be repeated
         *  later. */
        public function destroyQueued():void
        {
            Entity.destroyQueued(getClass(this), mId);
        }

        /** This method is called during a save operation when the server indicates that the entity
         *  has been modified since this client last loaded it. Handle any conflicts by updating
         *  the local object to the desired state. This state will then be stored on the server. */
        protected function onConflict(remoteEntity:Entity):void
        {
            // override in subclasses
        }

        // static methods
        
        /** Loads an entity with the given type and ID from the server.
         *  It is guaranteed that one (and only one) of the provided callbacks will be executed;
         *  all callback arguments are optional.
         *  
         *  <p>Note that the 'onError' callback may give you a cached version of the entity. This
         *  is possible if you have received the Entity already in the past. This might allow you
         *  to work with the entity even though the player has lost the connection to the Flox
         *  server.</p>
         * 
         *  <p>If there is no Entity with this type and ID stored on the server, the 'httpStatus'
         *  of the 'onError' callback will be 'HttpStatus.NOT_FOUND'.</p>
         *  
         *  @param entityClass  the class of the entity to load.
         *  @param id           the id of the entity to load.
         *  @param onComplete   executed when the operation is successful; function signature:
         *                      <pre>onComplete(entity:Entity):void;</pre>
         *  @param onError      executed when the operation was not successful; function signature:
         *                      <pre>onError(error:String, httpStatus:int, cachedEntity:Entity):void;</pre>
         */
        public static function load(entityClass:Class, id:String, 
                                    onComplete:Function, onError:Function):void
        {
            var entity:Entity;
            var type:String = getType(entityClass);
            var path:String = createEntityURL(type, id);
            
            Flox.service.request(HttpMethod.GET, path, null, onRequestComplete, onRequestError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                entity = Entity.fromObject(type, id, body);
                execute(onComplete, entity, httpStatus == HttpStatus.NOT_MODIFIED);
            }
            
            function onRequestError(error:String, httpStatus:int, cachedBody:Object):void
            {
                entity = Entity.fromObject(type, id, cachedBody); 
                execute(onError, error, httpStatus, entity);
            }
        }

        /** Deletes an entity with the given type and ID from the server.
         *  It is guaranteed that one (and only one) of the provided callbacks will be executed;
         *  all callback arguments are optional.
         * 
         *  <p>In case of an error, use the method 'HttpStatus.isTransientError(httpStatus)' to 
         *  find out if the error is just temporary (e.g. the server was not reachable).</p> 
         *  
         *  @param entityClass  the class of the entity that will be destroyed.
         *  @param id           the ID of the entity that will be destroyed.
         *  @param onComplete   executed when the operation is successful; function signature:
         *                      <pre>onComplete():void;</pre>
         *  @param onError      executed when the operation was not successful; function signature:
         *                      <pre>onError(error:String, httpStatus:int):void;</pre>         
         */
        public static function destroy(entityClass:Class, id:String, 
                                       onComplete:Function, onError:Function):void
        {
            var path:String = createEntityURL(getType(entityClass), id);
            Flox.service.request(HttpMethod.DELETE, path, null, onRequestComplete, onError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                execute(onComplete);
            }
        }
        
        /** Deletes an entity the next time the player goes online. When the Flox server cannot be
         *  reached at the moment, the request will be added to a queue and will be repeated
         *  later. */
        public static function destroyQueued(entityClass:Class, id:String):void
        {
            var path:String = createEntityURL(getType(entityClass), id);
            Flox.service.requestQueued(HttpMethod.DELETE, path);
        }
        
        private static function save(entity:Entity, onComplete:Function, onError:Function):void
        {
            var path:String = createEntityURL(entity.type, entity.id);
            Flox.service.request(HttpMethod.PUT, path, entity.toObject(), 
                                 onRequestComplete, onRequestError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                // createdAt and updatedAt are always set by server, thus we update them here.
                entity.createdAt = DateUtil.parse(body.createdAt);
                entity.updatedAt = DateUtil.parse(body.updatedAt);
                
                execute(onComplete, entity);
            }

            function onRequestError(error:String, httpStatus:int, cachedBody:Object):void
            {
                // If the entity was modified since we last fetched it,
                // we load the latest version and handle the conflict.

                if (httpStatus == HttpStatus.PRECONDITION_FAILED)
                    Entity.load(Object(entity).constructor, entity.id, onLoadComplete, onError);
                else
                    execute(onError, error, httpStatus, cachedBody);
            }

            function onLoadComplete(remoteEntity:Entity):void
            {
                entity.onConflict(remoteEntity);
                Entity.save(entity, onComplete, onError);
            }
        }
        
        private static function saveQueued(entity:Entity):void
        {
            var service:RestService = Flox.service;
            var path:String = createEntityURL(entity.type, entity.id);
            
            service.requestQueued(HttpMethod.PUT, path, entity.toObject());
            service.addEventListener(QueueEvent.QUEUE_PROCESSED,
                function onQueueProcessed(event:QueueEvent):void
                {
                    service.removeEventListener(QueueEvent.QUEUE_PROCESSED, onQueueProcessed);
                    
                    // createdAt and updatedAt are always set by server, thus we update them here.
                    var cachedObject:Object = Flox.service.getFromCache(path);
                    if (cachedObject)
                    {
                        entity.createdAt = DateUtil.parse(cachedObject.createdAt);
                        entity.updatedAt = DateUtil.parse(cachedObject.updatedAt);
                    }
                });
        }
        
        private static function refresh(entity:Entity, onComplete:Function, onError:Function):void
        {
            var path:String = createEntityURL(entity.type, entity.id);
            Flox.service.request(HttpMethod.GET, path, null, onRequestComplete, onError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                refreshEntity(entity, body);
                execute(onComplete, entity, httpStatus == HttpStatus.NOT_MODIFIED);
            }
        }
        
        // helpers

        /** @private */
        internal function toObject():Object
        {
            // create clone as Object & replace Dates with Strings
            return cloneObject(this, filterDate);
        }
        
        /** @private */
        internal static function fromObject(type:String, id:String, data:Object):Entity
        {
            var entity:Entity;
            
            if (data == null)
                return null;
            else if (type in sTypeCache)
                entity = new (sTypeCache[type] as Class)();
            else
                throw new Error("Entity type not recognized: " + type);
            
            entity.id = id;
            refreshEntity(entity, data);
            
            return entity;
        }
        
        /** @private */
        internal static function fromCache(type:String, id:String, eTag:String=null):Entity
        {
            var path:String = createEntityURL(type, id);
            var cachedObject:Object = Flox.service.getFromCache(path, null, eTag);
            
            if (cachedObject) return fromObject(type, id, cachedObject);
            else              return null;
        }
        
        private static function refreshEntity(entity:Entity, data:Object):void
        {
            if (entity == null || data == null) return;
            
            var typeDescription:XML = describeType(entity);
            
            for each (var variable:XML in typeDescription.variable)
            {
                updateProperty(entity, data, variable.@name.toString(),
                                             variable.@type.toString());
            }
            
            for each (var accessor:XML in typeDescription.accessor)
            {
                var access:String = accessor.@access.toString();
                if (access == "readwrite") 
                    updateProperty(entity, data, accessor.@name.toString(), 
                                                 accessor.@type.toString());
            }
        }
        
        private static function updateProperty(entity:Entity, serverData:Object, 
                                               propertyName:String, propertyType:String):void
        {
            if (propertyName in serverData)
            {
                if (propertyType == "Date")
                    entity[propertyName] = DateUtil.parse(serverData[propertyName]);
                else
                    entity[propertyName] = serverData[propertyName];
            }
        }
        
        private static function createEntityURL(type:String, id:String=null):String
        {
            return createURL("entities", type, id);
        }
        
        private static function filterDate(object:Object):Object
        {
            if (object is Date) return DateUtil.toString(object as Date);
            else return null;
        }
        
        // properties
        
        /** The type of the entity, which is per default the name of class. This is what
         *  groups Entities together on the server. */
        [NonSerialized]
        public function get type():String { return getType(getClass(this)); }
        
        /** This is the primary identifier of the entity. It must be unique within the objects of
         *  the same entity type. Allowed are alphanumeric characters, '-' and '_'. */
        public function get id():String { return mId; }
        public function set id(value:String):void
        { 
            if (/[^a-zA-Z0-9\-_]/.test(value))
                throw new Error("Invalid id: use only alphanumeric characters, '-', and '_'.");
            
            mId = value; 
        }
        
        /** The player ID of the owner of the entity. (Referencing a Player entity.) */
        public function get ownerId():String { return mOwnerId; }
        public function set ownerId(value:String):void { mOwnerId = value; }
        
        /** The access rights of all players except the owner.
         *  (The owner always has unlimited access.) */
        public function get publicAccess():String { return mPublicAccess; }
        public function set publicAccess(value:String):void { mPublicAccess = value ? value : ""; }
        
        /** The date when this entity was created. */
        public function get createdAt():Date { return mCreatedAt; }
        public function set createdAt(value:Date):void { mCreatedAt = value; }
        
        /** The date when this entity was last updated on the server. */
        public function get updatedAt():Date { return mUpdatedAt; }
        public function set updatedAt(value:Date):void { mUpdatedAt = value; }
        
        // TODO
        // public function get isSaved():Boolean { return ???; }
        
        // type registration
        
        /** @private
         *  Figures out the type of an entity class as it is used on the server. Per default, this 
         *  is just the class name. You can override this by adding "Type()" metadata to the class
         *  definition. */
        internal static function getType(entityClass:Class):String
        {
            for (var type:String in sTypeCache)
                if (sTypeCache[type] == entityClass) return type;
            
            var typeXml:XML = describeType(entityClass);
            var typeMetaData:XMLList = typeXml.metadata.(@name == "Type");
            var extendsPlayer:XMLList = typeXml.extendsClass.(@type == "com.gamua.flox::Player");
            
            if (typeMetaData.length()) 
                type = typeMetaData.arg.(@key=="").@value.toString();
            else if (extendsPlayer.length())
                type = ".player"; // that simplifies subclassing 'Player'
            else
                type = typeXml.@type.toString().split("::").pop();
            
            sTypeCache[type] = entityClass;
            return type;
        }
        
        /** @private */
        internal static function getClass(instance:Object):Class
        {
            return Object(instance).constructor;
        }
    }
}
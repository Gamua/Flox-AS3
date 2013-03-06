package com.gamua.flox
{
    import com.gamua.flox.utils.CustomEntity;
    
    import starling.unit.UnitTest;
    
    public class AccessTest extends UnitTest
    {
        private static const KEY_1:String = "key1";
        private static const KEY_2:String = "key2";
        
        public override function setUp():void
        {
            Constants.initFlox();
            Player.logout();
        }
        
        public override function tearDown():void
        {
            Flox.shutdown();
        }
        
        public function testAccessNone(onComplete:Function):void
        {
            makeAccessTest(Access.NONE, onComplete);
        }
        
        public function testAccessReadOnly(onComplete:Function):void
        {
            makeAccessTest(Access.READ, onComplete);
        }
        
        public function testAccessReadWrite(onComplete:Function):void
        {
            makeAccessTest(Access.READ_WRITE, onComplete);
        }
        
        public function makeAccessTest(access:String, onComplete:Function):void
        {
            var entity:CustomEntity = null;
            Player.loginWithKey(KEY_1, onLoginPlayer1Complete, onError);
            
            function onLoginPlayer1Complete(player:Player):void
            {
                assertEqual(AuthenticationType.KEY, player.authType);
                
                entity = new CustomEntity("Gandalf", 10001);
                entity.publicAccess = access;
                entity.save(onEntitySaved, onError);
            }
            
            function onEntitySaved(entity:CustomEntity):void
            {
                Player.logout(); // TODO: shouldn't be necessary -> server change required
                Player.loginWithKey(KEY_2, onLoginPlayer2Complete, onError);
            }
            
            function onLoginPlayer2Complete(player:Player):void
            {
                Entity.load(CustomEntity, entity.id, onEntityLoadComplete, onEntityLoadError); 
            }
            
            function onEntityLoadComplete(entity:CustomEntity):void
            {
                if (access == Access.NONE)
                {
                    fail("Could load entity that was not publicly accessible");
                    onComplete();
                }
                else if (access == Access.READ || access == Access.READ_WRITE)
                {
                    entity.name = "Saruman";
                    entity.save(onEntitySaveComplete, onEntitySaveError);
                }
            }
            
            function onEntitySaveComplete():void
            {
                if (access == Access.READ)
                    fail("Could save READ-only entity");

                onComplete();
            }
            
            function onEntitySaveError():void
            {
                if (access == Access.READ_WRITE)
                    fail("Could not modify READ_WRITE entity");
                
                onComplete();
            }
            
            function onEntityLoadError(error:String, transient:Boolean):void
            {
                if (access == Access.NONE)
                    assertFalse(transient);
                else
                    fail("Could not load entity with '" + access + "' access");
                
                onComplete();
            }
            
            function onError(error:String, httpStatus:int):void
            {
                fail("Entity handling failed: " + error);
                onComplete();
            }
        }
    }
}

import com.gamua.flox.Player;

class CustomPlayer extends Player
{
    private var mLastName:String;
    
    public function CustomPlayer(lastName:String="unknown")
    {
        mLastName = lastName;
    }
    
    public function get lastName():String { return mLastName; }
    public function set lastName(value:String):void { mLastName = value; }
}
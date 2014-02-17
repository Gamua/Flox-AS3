package com.gamua.flox
{
    import com.gamua.flox.utils.CustomEntity;
    import com.gamua.flox.utils.HttpStatus;
    
    import starling.unit.UnitTest;
    
    public class HeroTest extends UnitTest
    {
        public override function setUp():void
        {
            Constants.initFlox();
            Player.logout(); // create a new guest player for each test
        }
        
        public override function tearDown():void
        {
            Flox.shutdown();
        }
        
        public function testHero(onComplete:Function):void
        {
            var guestID:String = Player.current.id;
            var entity:CustomEntity = new CustomEntity("top secret", 20);
            entity.publicAccess = Access.NONE;
            entity.save(onSaveComplete, onError);
            
            function onSaveComplete(savedEntity:Entity):void
            {
                Player.loginWithKey(Constants.ENABLED_HERO_KEY, onLoginComplete, onError);
            }
            
            function onLoginComplete(hero:Player):void
            {
                assert(hero.id != Constants.ENABLED_HERO_KEY);
                Entity.load(CustomEntity, entity.id, onLoadComplete, onError);
            }
            
            function onLoadComplete(loadedEntity:CustomEntity):void
            {
                assertEqual(loadedEntity.id, entity.id, "wrong entity returned");
                assertEqual(loadedEntity.name, entity.name, "wrong name returned");
                assertEqual(loadedEntity.age, entity.age, "wrong age returned"),
                
                loadedEntity.age = 100;
                loadedEntity.save(onUpdateComplete, onError);
            }
            
            function onUpdateComplete(savedEntity:CustomEntity):void
            {
                assertEqual(savedEntity.ownerId, guestID, "owner of entity changed");
                assertEqual(savedEntity.age, 100, "wrong age saved");
                entity.destroy(onDestroyComplete, onError);
            }
            
            function onDestroyComplete():void
            {
                onComplete();
            }
            
            function onError(error:String):void
            {
                fail(error);
                onComplete();
            }
        }
        
        public function testDisabledHero(onComplete:Function):void
        {
            Player.loginWithKey(Constants.DISABLED_HERO_KEY, onLoginComplete, onLoginError);
            
            function onLoginComplete():void
            {
                fail("disabled hero could log in!");
                onComplete();
            }
            
            function onLoginError(error:String, httpStatus:int):void
            {
                assertEqual(httpStatus, HttpStatus.BAD_REQUEST, "wrong http status");
                onComplete();
            }
        }
    }
}
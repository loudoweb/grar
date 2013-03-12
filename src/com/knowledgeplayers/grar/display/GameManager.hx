package com.knowledgeplayers.grar.display;

import com.knowledgeplayers.grar.display.activity.ActivityDisplay;
import com.knowledgeplayers.grar.display.activity.ActivityManager;
import com.knowledgeplayers.grar.structure.activity.Activity;
import com.knowledgeplayers.grar.display.layout.Layout;
import nme.Lib;
import nme.events.EventDispatcher;
import nme.display.Sprite;
import com.knowledgeplayers.grar.util.KeyboardManager;
import nme.Lib;
import com.knowledgeplayers.grar.display.LayoutManager;
import com.knowledgeplayers.grar.display.part.PartDisplay;
import com.knowledgeplayers.grar.event.GameEvent;
import com.knowledgeplayers.grar.event.PartEvent;
import com.knowledgeplayers.grar.factory.DisplayFactory;
import com.knowledgeplayers.grar.structure.Game;
import com.knowledgeplayers.grar.structure.part.Part;
import nme.events.Event;

/**
 * Display of a game
 */

class GameManager extends EventDispatcher {
    /**
    * Instance of the game manager
    **/
    public static var instance (getInstance, null):GameManager;

    /**
     * The game model
     */
    public var game (default, default):Game;

    /**
     * Part currently displayed
     */
    public var currentPart (default, null):PartDisplay;

    private var layout:Layout;
    private var activityDisplay:ActivityDisplay;

    /**
    * @return the instance of the singleton
    **/

    public static function getInstance():GameManager
    {
        if(instance == null)
            instance = new GameManager();
        return instance;
    }

    public function setLayout(layout:String):Void
    {
        this.layout = LayoutManager.instance.getLayout(layout);
    }

    /**
    * Start the game
    * @param    game : The game to start
    * @param    layout : The layout to display
    **/

    public function startGame(game:Game, layout:String = "default"):Void
    {
        this.game = game;
        setLayout(layout);
        Lib.current.addChild(this.layout.content);
        displayPartById(0);
    }

    /**
    * Display a graphic representation of the given part
    * @param part : The part to display
    **/

    public function displayPart(part:Part):Void
    {
        // Cleanup
        if(currentPart != null){
            currentPart.unLoad();
        }

        // Display the new part
        currentPart = DisplayFactory.createPartDisplay(part);
        if(currentPart == null)
            dispatchEvent(new GameEvent(GameEvent.GAME_OVER));
        else{
            currentPart.addEventListener(PartEvent.EXIT_PART, onExitPart);
            currentPart.addEventListener(PartEvent.PART_LOADED, onPartLoaded);
            currentPart.addEventListener(PartEvent.ENTER_SUB_PART, onEnterSubPart);
        }
    }

    public function displayActivity(activity:Activity):Void
    {
        onActivityEnd(null);
        if(currentPart != null)
            currentPart.visible = false;
        activity.addEventListener(PartEvent.EXIT_PART, onActivityEnd);
        var activityName:String = Type.getClassName(Type.getClass(activity));
        activityName = activityName.substr(activityName.lastIndexOf(".") + 1);
        activityDisplay = ActivityManager.instance.getActivity(activityName);
        activityDisplay.addEventListener(Event.COMPLETE, onActivityReady);
        activityDisplay.model = activity;
    }

    /**
    * Display a graphic representation of the part with the given ID
    * @param id : The ID of the part to display
    **/

    public function displayPartById(id:Int):Void
    {
        displayPart(game.start(id));

    }

    // Privates

    private function new()
    {
        super();
        // Set Keyboard Manager
        KeyboardManager.instance.game = this;
    }

    // Handlers

    private function onExitPart(event:Event):Void
    {
        displayPartById(currentPart.part.id + 1);
    }

    private function onPartLoaded(event:PartEvent):Void
    {
        var partDisplay = cast(event.target, PartDisplay);
        partDisplay.startPart();
        layout.zones.get("main").addChild(partDisplay);
    }

    private function onExitSubPart(event:PartEvent):Void
    {
        var subPart = cast(event.target, PartDisplay);
        subPart.unLoad();
        layout.zones.get("main").removeChild(subPart);
        currentPart.visible = true;
    }

    public function onEnterSubPart(event:PartEvent):Void
    {
        currentPart.visible = false;
        var subPart:PartDisplay = DisplayFactory.createPartDisplay(event.part);
        subPart.addEventListener(PartEvent.EXIT_PART, onExitSubPart);
        subPart.addEventListener(PartEvent.PART_LOADED, onPartLoaded);
    }

    private function onActivityReady(e:Event):Void
    {
        layout.zones.get("main").addChild(activityDisplay);
        activityDisplay.startActivity();
    }

    private function onActivityEnd(e:PartEvent):Void
    {
        if(e != null)
            e.target.removeEventListener(PartEvent.EXIT_PART, onActivityEnd);
        if(activityDisplay != null && layout.zones.get("main").contains(activityDisplay))
            layout.zones.get("main").removeChild(activityDisplay);
        activityDisplay = null;
        if(currentPart != null){
            currentPart.visible = true;
            currentPart.nextElement();
        }
    }
}

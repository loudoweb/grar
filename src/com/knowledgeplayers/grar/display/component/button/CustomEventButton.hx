package com.knowledgeplayers.grar.display.component.button;
import com.knowledgeplayers.grar.display.element.AnimationDisplay;
import nme.Lib;
import aze.display.TilesheetEx;
import com.knowledgeplayers.grar.event.ButtonActionEvent;
import nme.events.MouseEvent;

/**
 * Button with a customizable event
 * @author jbrichardet
 */

class CustomEventButton extends DefaultButton {
    /**
     * Type of the event to dispatch
     */
    public var eventType (default, default):String;

    /**
     * Control whether or not the native event (CLICK) must be propagated
     */
    public var propagateNativeEvent (default, default):Bool = false;

    public var activToggle:Bool =false;

    private var toggle:Bool = true;

    private var toggleOn:AnimationDisplay;
    private var toggleOff:AnimationDisplay;
    private var toggleActived:AnimationDisplay;

    /**
     * Constructor
     * @param	eventName : Name of the customed event to dispatch
     * @param	tilesheet : UI sheet
     * @param	tile : Tile containing the button
     */

    private var animations:Hash<AnimationDisplay>;
    private var animEnCours:AnimationDisplay;

    public function new(tilesheet:TilesheetEx, tile:String, eventName:String,?_animations:Hash<AnimationDisplay>,?_toggle:String)
    {
        super(tilesheet, tile);
        this.eventType = eventName.toLowerCase();
        animations = _animations;
        animEnCours =null;
        if(_toggle =="true")
        {
            activToggle = true;
        }

        if(animations != null)setAnimations(animations);
    }

    private function setAnimations(_animations:Hash<AnimationDisplay>):Void{

        for(key in _animations.keys()){

            var anim:AnimationDisplay = cast(_animations.get(key),AnimationDisplay);
            if(activToggle)
            {
                if(key == "over")
                {
                    toggleActived = toggleOn = anim;
                }if(key == "out")
                {
                    toggleOff= anim;
                }

                addChild(toggleActived);

            }else if(key != "over")
            {
                addChild(anim);
                animElement(key);
            }
        }
    }

    override private function onOver(event:MouseEvent):Void{

            if(!activToggle){
                super.clipOver();
                if(animations!=null)animElement("over");
            }
        else{
                toggleActived.goto(1);
            }
    }
    override private function onOut(event:MouseEvent):Void{

            if(!activToggle){
                super.clipOut();
                if(animations!=null)animElement("out");
            }
        else
            {
                toggleActived.goto(0);
            }
    }

    override private function onClick(event:MouseEvent):Void
    {


        if(activToggle) changeToggle();
        if(!propagateNativeEvent)
            event.stopImmediatePropagation();

        var e = new ButtonActionEvent(eventType);
        dispatchEvent(e);
    }

    private function changeToggle():Void{

        removeChild(toggleActived);
        if(toggle){
            //super.clipOver();

            toggleActived = toggleOff;
            toggle = false;
        }else
        {
            //super.clipOut();
            toggleActived = toggleOn;
            toggle = true;
        }
        addChild(toggleActived);
        toggleActived.goto(0);

    }

    private function animElement(_type:String):Void{

        if(animations != null){
            if(animEnCours != null)removeChild(animEnCours);

            var anim:AnimationDisplay = cast(animations.get(_type),AnimationDisplay);
            animEnCours = anim;
            addChild(anim);
            anim.animElement();
        }


    }
}
package com.knowledgeplayers.grar.display.component.container;

import com.knowledgeplayers.grar.event.PartEvent;
import com.knowledgeplayers.grar.display.GameManager;
import flash.media.SoundTransform;
import com.knowledgeplayers.grar.display.element.ChronoCircle;
import flash.events.Event;
import flash.net.URLRequest;
import flash.media.SoundChannel;
import flash.media.Sound;
import haxe.ds.GenericStack;
import flash.display.Sprite;
import haxe.xml.Fast;
import aze.display.TilesheetEx;

class SoundPlayer extends WidgetContainer
{
    public var playButtons (default, default): GenericStack<DefaultButton>;

	public var autoPlay (default, default):Bool;

    public var urlSound:String;
    private var isPlaying: Bool = false;
    private var sound:Sound;
    private var soundChannel:SoundChannel;
    private var pausePosition:Float=0;
    private var chrono:ChronoCircle;
	private var loaded:Bool;
	private var defaultVolume:Float;

    public function new(?xml: Fast, ?tilesheet: TilesheetEx,?_urlSound:String)
    {
	    playButtons = new GenericStack<DefaultButton>();

        super(xml, tilesheet);
        urlSound = _urlSound;
        soundChannel = new SoundChannel();
    }

    public function setSound(url:String, autoStart:Bool = false, loop:Bool = false, defaultVolume:Float = 1, capture:Float = 0,?autoFullscreen:Bool): Void{


        var nbPlay:Int= 0;
        if(loop)
            {
                nbPlay=999;
            }
        if(url == null || url == "")
            throw '[SoundPlayer] Invalid url "$url" for audio stream.';

	    autoPlay = autoStart;
	    this.defaultVolume = defaultVolume;
	    loaded = false;
	    var req:URLRequest = new URLRequest(url);
	    sound = new Sound();
	    sound.addEventListener(Event.COMPLETE, function(e){
	        loaded = true;
		    if(autoPlay)
			    playSound(nbPlay);
	    });
	    sound.load(req);
    }

	public function playSound(?nbPlay:Int):Void
	{
		if(loaded){
			setPlaying(true);
			var master = GameManager.instance.masterVolume;
			var volume = new SoundTransform(master == 1 ? defaultVolume : master);
			soundChannel = sound.play(pausePosition,nbPlay);
			soundChannel.soundTransform = volume;
			soundChannel.addEventListener(Event.SOUND_COMPLETE,onSoundComplete);
		}
		else{
			autoPlay = true;
		}
	}

	public function pauseSound():Void
	{
		pausePosition = soundChannel.position;
		setPlaying(false);
		soundChannel.stop();
	}

    override public function createElement(elemNode:Fast):Widget
    {
        var widget = super.createElement(elemNode);
		if(Std.is(widget, ChronoCircle))
			chrono = cast(widget, ChronoCircle);
        return widget;
    }

	// Privates

    override private function setButtonAction(button:DefaultButton, action:String):Void
    {
        if(action == "play"){
            playButtons.add(button);
            button.buttonAction = playOrPause;
        }
    }

    private function playOrPause(?target: DefaultButton)
    {
        if(!isPlaying)
            playSound();
        else
            pauseSound();
    }

    private function onSoundComplete(e:Event):Void
    {
        pausePosition = 0;
	    setPlaying(false);
    }

    private function setPlaying(isPlaying: Bool)
    {
        if(isPlaying)
	        addEventListener(Event.ENTER_FRAME, onEnterFrame);
	    else
	        removeEventListener(Event.ENTER_FRAME, onEnterFrame);

        for(button in playButtons)
            button.toggle(!isPlaying);
        this.isPlaying = isPlaying;
    }

	private function onEnterFrame(e:Event):Void
	{   if(chrono !=null)
		    chrono.updatePicture((sound.length - soundChannel.position)/sound.length);
	}
}
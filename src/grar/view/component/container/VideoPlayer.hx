package grar.view.component.container;

import motion.Actuate;

import aze.display.TileLayer;
import aze.display.TileClip;
import aze.display.TileSprite;
import aze.display.TilesheetEx;

import com.knowledgeplayers.grar.display.TweenManager;
import grar.view.component.container.WidgetContainer;
import grar.util.DisplayUtils;

import flash.display.Bitmap;
import flash.display.Sprite;
import flash.display.BitmapData;
import flash.display.Stage;
import flash.display.StageDisplayState;
import flash.display.DisplayObject;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.media.SoundTransform;
import flash.media.Video;
import flash.events.NetStatusEvent;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.Lib;

import haxe.ds.GenericStack;

typedef SuperBool = {

	var isSet: Bool;
	var value : Bool;
}

typedef SliderData = {

	var x : Float;
	var y : Float;
	var bar : { tile : TileImageData, x : Float, y : Float };
	var cursor : { tile : TileImageData, ref : String, x : Float : 0, y : Float, vol : Float };
}

typedef ProgressBarData = {

	var x : Float;
	var y : Float;
	var mask : TileImageData;
	var bar : { color : Int, alpha : Float, x : Float, y : Float };
	var cursor : { tile : TileImageData, ref : String, x : Float };
}

typedef BackgroundData = {

	var color : Int;
	var alpha : Float;
	var x : Float;
	var y : Float;
	var w : Float;
	var h : Float;
}

class VideoPlayer extends WidgetContainer {

	//public function new(?xml: Fast, ?tilesheet: TilesheetEx)
	public function new(vpd : WidgetContainer) {

		playButtons = new GenericStack();
		controls = new GenericStack();
		containerVideo = new Sprite();
		containerControls = new Sprite();
        containerThumbnail = new Sprite();
        containerThumbnail.mouseChildren = false;
        containerThumbnail.mouseEnabled = false;

		addChild(containerVideo);
        addChild(containerThumbnail);

		xVideo = containerVideo.x;
		yVideo = containerVideo.y;
		xControls = containerControls.x;
		yControls = containerControls.y;
		autoFullscreen = {isSet: false, value: false};


		//super(xml, tilesheet);
		super(vpd);

		video = new Video();

        containerThumbnail.addChild(displays.get("thumbnail"));
		connection = new NetConnection();
		connection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
		addEventListener(Event.REMOVED_FROM_STAGE , unsetVideo, false, 0, true);
		connection.connect(null);

		for(i in 0...content.numChildren){
			if(Std.is(content.getChildAt(i), Widget)){
				controls.add(cast(content.getChildAt(i), Widget));
			}
		}
		if(displays.exists("time")){
			timeArea = cast(displays.get("time"), ScrollPanel);
			controls.add(timeArea);
		}

		if (displays.exists("timeCurrent")){
			timeCurrent = cast(displays.get("timeCurrent"), ScrollPanel);
			controls.add(timeCurrent);
		}

		if (displays.exists("timeTotal")){
			timeTotal = cast(displays.get("timeTotal"), ScrollPanel);
			controls.add(timeTotal);
		}

		yBigPlay =  displays.get("bigPlay").y;

		switch(vpd.type) {

			case VideoPlayer(ch, af):

				controlsHidden = ch;

				if (af != null) {

					autoFullscreen.value = af;
					autoFullscreen.isSet = true;
				}

			default: // hidden
		}

		init();
	}

	public var playButtons (default, default): GenericStack<DefaultButton>;
	public var fullscreenButton (default, default):DefaultButton;
	public var soundButton (default, default):DefaultButton;
	private var isPlaying: Bool = false;
	private var isFullscreen: Bool = false;
	private var displayHours: Bool = false;
	private var totalLength: Int = 0;

	private var connection : NetConnection;
	private var stream : NetStream;
	private var video : Video;

	private var loop : Bool;
	private var autoStart : Bool;
	private var autoFullscreen : SuperBool;
	private var progressBar: Image;
	private var controls: GenericStack<Widget>;
	private var timeArea: ScrollPanel;
	private var timeCurrent: ScrollPanel;
	private var timeTotal: ScrollPanel;
	private var controlsHidden: Bool = false;
	private var controlsVisible: Bool = false;
	private var cursor: Widget;
	private var lockCursor: Bool;
	private var soundSlider: Image;
	private var soundCursor: Widget;
	private var containerVideo:Sprite;
	private var containerControls:Sprite;
	private var containerThumbnail:Sprite;

	private var xVideo:Float=0;
	private var xControls:Float=0;
	private var yVideo:Float=0;
	private var yControls:Float=0;
	private var yBigPlay:Float=0;
	private var blackScreen:Sprite;
	//private var _timeToCapture : Float = 0;
	private var backgroundControls:Widget;
    private var volumeEnCours:Float = 0;
    private var ratioEnCours:Float = 1;

	dynamic private function onVideoPlay(){};

	public function setVideo(url:String, autoStart:Bool = false, loop:Bool = false, defaultVolume:Float = 1, capture:Float = 0, autoFullscreen:Bool = false,?thumbnail:String, ?onVideoPlay: Void -> Void): Void
	{
		if(url == null || url == "")
			throw '[VideoPlayer] Invalid url "$url" for video stream.';
		//if(stream != null)
		//	init();
		//_timeToCapture = capture
		stream = new NetStream(connection);
		this.loop = loop;
		this.autoStart = autoStart;

		if(!this.autoFullscreen.isSet){
			this.autoFullscreen.value = autoFullscreen;
			this.autoFullscreen.isSet = true;
		}
        if (thumbnail != null){
            var thumb:Image =   cast(displays.get("thumbnail"),Image);
            thumb.setBmp(thumbnail);
            video.visible =false;
        }

		changeVolume(defaultVolume);
		var videoWidth = 0;
		var videoHeight = 0;
		stream.client = {onMetaData: function(data){
			totalLength = Math.round(data.duration);

			// Resizing video with original ratio
			var ratio = video.videoWidth / video.videoHeight;
			video.width = maskWidth;
			video.height = maskWidth/ratio;
			video.x = (containerVideo.width - video.width) / 2;
			video.y = (containerVideo.height - video.height) / 2;

			// When ready, start video
			if(autoStart)
				playVideo();
			else{
				pauseVideo();
			}
			stream.client = {};
		}};
		stream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
		// TODO bufferTime en fonction de la BP
		//stream.bufferTime = startBufferLength;
		stream.play(url);
		stream.seek(0);
		video.attachNetStream(stream);
		video.smoothing = true;

		containerVideo.addChild(video);

		DisplayUtils.initSprite(containerVideo, maskWidth, maskHeight);
		if(onVideoPlay != null)
			this.onVideoPlay = onVideoPlay;
	}

	public function playVideo(?target: DefaultButton):Void
	{
        video.visible =true;
		addChild(containerControls);
		addEventListener(Event.ENTER_FRAME, enterFrame);
        stream.addEventListener(NetStatusEvent.NET_STATUS,statusHandler);
		onVideoPlay();
		setPlaying(true);
		stream.resume();
        if(autoFullscreen.value){
           Actuate.timer(0.01,null).onComplete(waitForIt);
        }
	}

    //TODO FULL ... wait for it ... SCREEN
    public function waitForIt():Void
    {
        setFullscreen(true);
    }

    public function statusHandler(event:NetStatusEvent):Void
    {
        switch (event.info.code)
        {
            //case "NetStream.Play.Start":

            case "NetStream.Play.Stop":

                    cursor.x = progressBar.x-cursor.width/2;
                    fastForward(0);
                    setFullscreen(false);
                    containerThumbnail.visible=true;
                    if(!loop)
                        stopVideo();

                    dispatchEvent(new Event(Event.COMPLETE));
        }
    }

	public function pauseVideo():Void
	{
		removeEventListener(Event.ENTER_FRAME, enterFrame);
		setPlaying(false);
		stream.pause();
	}

	public function stopVideo():Void
	{
		removeEventListener(Event.ENTER_FRAME, enterFrame);
		setPlaying(false);
		if(contains(containerControls))
			removeChild(containerControls);
        containerThumbnail.visible=true;
        displays.get("bigPlay").visible=true;
		if(stream != null){
			stream.pause();
			fastForward(0);
		}
	}

	private function playOrPause(?target: DefaultButton)
	{
		displays.get("bigPlay").visible = false;
		containerThumbnail.visible=false;
		if(!isPlaying)
			playVideo();
		else
			pauseVideo();
	}

	public function unsetVideo (?e:Event):Void
	{
		removeEventListener(Event.REMOVED_FROM_STAGE , unsetVideo);
		video.clear();
		stream.close();
	}

	public function toggleFullScreen(?target: DefaultButton)
	{
		setFullscreen(!isFullscreen);
	}

    public function toggleSound(?target: DefaultButton)
	{

        if(target.toggleState=="active"){

            volumeEnCours = 0;
        }
        else{

            volumeEnCours = ratioEnCours;
        }
        changeVolume(volumeEnCours);
	}

	public function hideControllers():Void
	{
		removeChild(displays.get("bigPlay"));
		containerControls.visible = false;
	}

	public function setFullscreen(fullscreen:Bool):Void
	{
		// Disable call is fullscreen is already at the desire state
		if(isFullscreen == fullscreen)
			return;

		isFullscreen = fullscreen;

		if (isFullscreen) {

			blackScreen = new Sprite();
			blackScreen.graphics.beginFill(0);
			blackScreen.graphics.drawRect(0,0,Lib.current.width,Lib.current.height);
			blackScreen.graphics.endFill();
			Lib.current.stage.addChild(blackScreen);

			Lib.current.stage.addChild(containerVideo);
			Lib.current.stage.addChild(containerControls);
			containerVideo.scaleX = Math.min((Lib.current.stage.stageWidth / video.width), (Lib.current.stage.stageHeight / video.height));
			containerVideo.scaleY =  containerVideo.scaleX;

			containerVideo.x = Lib.current.stage.stageWidth/2-containerVideo.width/2;
			containerVideo.y = Lib.current.stage.stageHeight/2-containerVideo.height/2;

            containerControls.x = Lib.current.stage.stageWidth/2-containerControls.width/2;
			containerControls.y = Lib.current.stage.stageHeight - containerControls.height - 20;

			displays.get("bigPlay").y = Lib.current.stage.stageHeight/2-displays.get("bigPlay").height/2-containerControls.y ;
			fullscreenButton.toggle();

		}
		else {
			if (blackScreen !=null)
				Lib.current.stage.removeChild(blackScreen);

			addChild(containerVideo);
            addChild(containerThumbnail);
			addChild(containerControls);
            addChild(displays.get("bigPlay"));
			stage.displayState = StageDisplayState.NORMAL;
			containerVideo.width = maskWidth;
			containerVideo.height = maskHeight;
			containerVideo.x = xVideo;
			containerVideo.y = yVideo;
			containerControls.x = xControls;
			containerControls.y = yControls;
			fullscreenButton.toggle();
			displays.get("bigPlay").y = yBigPlay;

		}
	}

	public function imageCapture():BitmapData {
		var bmp:BitmapData = new BitmapData(Math.round(width), Math.round(height));
		bmp.draw(this);
		return bmp;
	}


	override public function createElement(de : ElementData) : Widget {

		var widget : Widget = super.createElement(de);

		switch (de) {

			case VideoBackground(d):

				backgroundControls = new Widget();

				backgroundControls.graphics.beginFill(d.color,d.alpha);
				backgroundControls.graphics.drawRect(d.x,d.y,d.w,d.h);
				backgroundControls.graphics.endFill();

				controls.add(backgroundControls);
				addElement(backgroundControls);


			case VideoProgressBar(d):

				progressBar = new Image();
				//progressBar.ref = elemNode.att.ref;
				progressBar.x = d.x;
				progressBar.y = d.y;
				addElement(progressBar);
				
				var mask : Sprite = null;
				d.mask.layer = layer;
				var mt : TileImage = new TileImage(d.mask);
				mt.x = (progressBar.x + mt.width/2);
				mt.y = (progressBar.y + mt.height/2);
				mask = mt.getMask();
				mask.width = child.has.width ? Std.parseFloat(d.mask.id.width) : mt.width;

				var bar = new Sprite();
				DisplayUtils.initSprite(bar, mask.width, mask.height, d.bar.color, d.bar.alpha, d.bar.x, d.bar.y);
				bar.scaleX = 0;
				progressBar.addChild(bar);

				d.cursor.tile.layer = new TileLayer(layer.tilesheet);
				var ct : TileImage = new TileImage(d.cursor.tile);
				cursor = new Widget();
				cursor.ref = d.cursor.ref;
				cursor.addChild(new Bitmap(DisplayUtils.getBitmapDataFromLayer(ct.tileSprite.layer.tilesheet, ct.tileSprite.tile)));
				cursor.x = d.cursor.x + progressBar.x - cursor.width / 2;
				cursor.y = progressBar.y - cursor.height / 3;
				addElement(cursor);

				progressBar.mask = mask;
				progressBar.mouseChildren = false;
				mask.mouseEnabled = false;
				content.addChild(mask);

				controls.add(progressBar);


			case VideoSlider(d):

				soundSlider = new Image();
				//soundSlider.ref = elemNode.att.ref;
				soundSlider.x = d.x;
				soundSlider.y = d.y;

				d.bar.tile.layer = new TileLayer(layer.tilesheet);
				var bt : TileImage = new TileImage(d.bar.tile);
				var cur = new Bitmap(DisplayUtils.getBitmapDataFromLayer(bt.tileSprite.layer.tilesheet, bt.tileSprite.tile));
				cur.x = d.bar.x;
				cur.y = d.bar.y;
				soundSlider.addChild(cur);

				d.cursor.tile.layer = new TileLayer(layer.tilesheet);
				var ct : TileImage = new TileImage(d.cursor.tile);
				soundCursor = new Widget();
				soundCursor.ref = d.cursor.ref;
				soundCursor.addChild(new Bitmap(DisplayUtils.getBitmapDataFromLayer(ct.tileSprite.layer.tilesheet, ct.tileSprite.tile)));
				soundCursor.x = d.cursor.x + soundSlider.x + d.cursor.vol * soundSlider.width - soundCursor.width / 2;
				soundCursor.y = d.cursor.y + soundSlider.y;
				addElement(soundCursor);

				soundSlider.mouseChildren = false;
				controls.add(soundSlider);
				addElement(soundSlider);

			default: // nothing
		}

		return widget;
	}


	///
	// INTERNALS
	//

	private function init():Void
	{
		content.setChildIndex(layer.view,1);

		progressBar.addEventListener(MouseEvent.CLICK, onClickTimeline);
		cursor.buttonMode = true;
		cursor.addEventListener(MouseEvent.MOUSE_DOWN, dragCursor);
		soundCursor.buttonMode = true;
		soundCursor.addEventListener(MouseEvent.MOUSE_DOWN, dragSoundCursor);
		soundSlider.addEventListener(MouseEvent.CLICK, onClickSoundLine);
		if(timeArea != null)
			timeArea.setContent(videoTimeConvert(0) + "/" + videoTimeConvert(0));

		if(timeCurrent != null)
			timeCurrent.setContent(videoTimeConvert(0));

		if(timeTotal != null)
			timeTotal.setContent(videoTimeConvert(0));

		containerControls.addChild(content);

		addChild(displays.get("bigPlay"));

		containerControls.addEventListener(MouseEvent.MOUSE_OVER,showControls);
		containerControls.addEventListener(MouseEvent.MOUSE_OUT,hideControls);

		containerVideo.addEventListener(MouseEvent.MOUSE_MOVE,onMouseMove);
		containerControls.alpha = 0;
	}

	private function onMouseMove(e:MouseEvent):Void{
		checkPositionMouse();
	}

	private function dragCursor(e:MouseEvent):Void
	{
		cursor.startDrag(false, new Rectangle(progressBar.x-cursor.width/2,progressBar.y-cursor.height/3,progressBar.width, 0));
		containerControls.addEventListener(MouseEvent.MOUSE_UP, dropCursor);
	}

	private function dragSoundCursor(e:MouseEvent):Void
	{
		soundCursor.startDrag(false, new Rectangle(soundSlider.x-soundCursor.width/2,soundSlider.y,soundSlider.width, 0));
		containerControls.addEventListener(MouseEvent.MOUSE_UP, dropSoundCursor);
	}

	private function dropCursor(e:MouseEvent):Void
	{
		cursor.stopDrag();
        containerControls.removeEventListener(MouseEvent.MOUSE_UP, dropCursor);
		var ratio = (cursor.x + cursor.width/2 - progressBar.x) / progressBar.width;
		fastForward(ratio);
	}

	private function dropSoundCursor(e:MouseEvent):Void
	{
		soundCursor.stopDrag();
		removeEventListener(MouseEvent.MOUSE_UP, dropSoundCursor);
		var ratio = (soundCursor.x + soundCursor.width/2 - soundSlider.x) / soundSlider.width;
        if(ratio>0.2){
            ratioEnCours = (soundCursor.x + soundCursor.width/2 - soundSlider.x) / soundSlider.width;
            soundButton.toggle(true);
        }
        else {
            soundButton.toggle(false);
        }
		changeVolume(ratio, false);
	}

	private function fastForward(ratio: Float):Void
	{
		var position = Math.floor(totalLength)*ratio;
		stream.seek(position);
		lockCursor = true;
	}

	private function changeVolume(ratio:Float, moveCursor: Bool = true):Void
	{
        if(ratio <0.2){

            ratio = 0;
        }else
        {

        }
		stream.soundTransform = new SoundTransform(ratio);
		if(moveCursor)
			soundCursor.x = soundSlider.width*ratio+soundSlider.x - soundCursor.width /2;

        volumeEnCours = ratio;


	}

	private function onClickTimeline(e:MouseEvent):Void
	{
		var ratio = e.localX / progressBar.width;
		fastForward(ratio);
	}

	private function onClickSoundLine(e:MouseEvent):Void
	{
		var ratio = e.localX / soundSlider.width;

        if(ratio>0.2){
            ratioEnCours = ratio;
            soundButton.toggle(true);
        }
        else {
            soundButton.toggle(false);
        }
		changeVolume(ratio);
	}

	private function onCaptureImage():Void{
		/*removeEventListener(Event.ENTER_FRAME, enterFrame);
		stream.pause();
		stream.seek(_timeToCapture);
		stream.resume();
		bCapture = true;
		_mc.barBg_mc._play.gotoAndStop(2);
		dispatchEvent(new BitmapCaptureEvent(BitmapCaptureEvent.CAPTURE,imageCapture(),true));
		addEventListener(Event.ENTER_FRAME, enterFrame);*/
	}

	private function enterFrame(?e:Event):Void
	{
		var nowSecs:Float = Math.floor(stream.time);
		var totalSecs:Float = Math.floor(totalLength);

		/*if (bCapture2) {
			if (nowSecs >= (_timeToCapture)) {
				dispatchEvent(new BitmapCaptureEvent(BitmapCaptureEvent.CAPTURE,imageCapture(),true));
				bCapture2 = false;
			}
		}*/

		if(nowSecs > 0)	{
			if(timeArea != null)
				timeArea.setContent("-"+videoTimeConvert(nowSecs) + "/" + videoTimeConvert(totalSecs));

			if(timeCurrent != null)
				timeCurrent.setContent(videoTimeConvert(nowSecs));

			if(timeTotal != null)
				timeTotal.setContent(videoTimeConvert(totalSecs));

			var amountPlayed:Float = nowSecs / totalSecs;
			var amountLoaded:Float = stream.bytesLoaded / stream.bytesTotal;
			var oldWidth = progressBar.getChildAt(1).width;
			progressBar.getChildAt(1).scaleX = amountPlayed;
			progressBar.getChildAt(0).scaleX = amountLoaded;
			if(!lockCursor){
				cursor.x += progressBar.getChildAt(1).width - oldWidth;
			}
			else{
				cursor.x = progressBar.getChildAt(1).width + progressBar.x - cursor.width/2;
				lockCursor = false;
			}
		}
	}

	private function netStatusHandler(event:NetStatusEvent):Void {
		/*switch (event.info.code) {
			case "NetStream.Buffer.Full":
				stream.bufferTime = xpandedBufferLength;
				if (_timeToCapture > 0 && !bCapture) {
					bCapture = true;
					onCaptureImage();
				}
				if (bCapture) {
					bCapture2 = true;
				}

			case "NetStream.Buffer.Empty":
				stream.bufferTime = startBufferLength;
		}*/
	}

	private function videoTimeConvert(pTime: Float):String {
		var tempNum = pTime;
		var minutes = Math.floor(tempNum / 60);
		var hours: Float = 0;
		var currentTimeConverted: String;
		if (displayHours && minutes/60 >= 1) {
			hours = Math.floor(minutes / 60);
			currentTimeConverted = hours+":";
		}
		else
			currentTimeConverted = "";
		var seconds = Math.round(tempNum - (minutes * 60));

		return currentTimeConverted + (minutes < 10 ? "0":"")+ minutes + ":" +(seconds < 10 ? "0":"")+seconds;
	}

	private function setPlaying(isPlaying: Bool){
		for(button in playButtons)
			button.toggle(!isPlaying);
		this.isPlaying = isPlaying;
	}

	private function showControls(e:MouseEvent=null):Void
	{
		if(controlsHidden){
			TweenManager.stop(containerControls);
			TweenManager.applyTransition(containerControls, "fadeInVideoControls").onComplete(checkAgain);
		}
	}

	private function hideControls(e:MouseEvent=null):Void
	{

		if(controlsHidden){
			TweenManager.stop(containerControls);

			TweenManager.applyTransition(containerControls, "fadeOutVideoControls",3);
		}

	}

	private function checkPositionMouse():Void{

		if(containerVideo.hitTestPoint(Lib.current.stage.mouseX,Lib.current.stage.mouseY)){
			showControls();

		}else{
			hideControls();
		}
	}
    private function checkAgain():Void{

		if(containerVideo.hitTestPoint(Lib.current.stage.mouseX,Lib.current.stage.mouseY)){
            hideControls();
        }
	}

	override private function setButtonAction(button:DefaultButton, action:String):Void
	{
		if(action == "play"){
			playButtons.add(button);
			button.buttonAction = playOrPause;

		}
		else if(action == "fullscreen"){
			fullscreenButton = button;
			button.buttonAction = toggleFullScreen;
		}
        else if(action == "sound"){
            soundButton = button;
            button.buttonAction = toggleSound;
        }
		controls.add(button);


	}
}
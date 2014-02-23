package grar.view;

import aze.display.TileLayer;
import aze.display.TilesheetEx;

import grar.view.contextual.NotebookDisplay;
import grar.view.contextual.menu.MenuDisplay;
import grar.view.element.ChronoCircle;
import grar.view.element.Timeline;
import grar.view.component.container.SoundPlayer;
import grar.view.component.container.DefaultButton;
import grar.view.component.container.SimpleContainer;
import grar.view.component.ScrollBar;
#if flash
import grar.view.component.container.VideoPlayer;
#end
import grar.view.component.TileImage;
import grar.view.component.Widget;
import grar.view.component.Image;
import grar.view.component.container.DefaultButton;
import grar.view.component.container.ScrollPanel;
import grar.view.component.CharacterDisplay;

import com.knowledgeplayers.grar.factory.UiFactory; // FIXME
import com.knowledgeplayers.grar.event.ButtonActionEvent; // FIXME

import grar.util.DisplayUtils;

import flash.geom.Rectangle;
import flash.events.Event;
import flash.display.DisplayObject;
import flash.display.Sprite;

import haxe.ds.GenericStack;
import haxe.ds.StringMap;

using StringTools;

typedef Template = {

	var data : { data : ElementData, validation : Null<String> };
	var z : Int;
}

enum ElementData {

	TextGroup(data : StringMap<{ obj : ElementData, z : Int }>); // TODO CHECK param
	Image(i : ImageData);
	TileImage(ti : TileImageData);
	CharacterData(c : CharacterData);
	DefaultButton(d : WidgetContainerData);
	ScrollPanel(d : WidgetContainerData);
	VideoPlayer(d : WidgetContainerData);
	SoundPlayer(d : WidgetContainerData);
	ScrollBar(d : { width : Float, bgColor : Null<String>, cursorColor : Null<String>, bgTile : Null<String>, tile : String, tilesheet : Null<String>, cursor9Grid : Array<Float>, bg9Grid : Null<Array<Float>> });
	SimpleContainer(d : WidgetContainerData);
	ChronoCircle(d : WidgetContainerData);
	Template(d : { data : ElementData, validation : Null<String> });

	// PartDisplay only
	InventoryDisplay(d : WidgetContainerData);
	IntroScreen(d : WidgetContainerData);

	// Zone only
	Menu(d : DisplayData);
	ProgressBar(d : WidgetContainerData);
}

enum DisplayType {

	Display; // TODO remove ?
	Part;
	Activity( ? groups : StringMap<{ x : Float, y : Float, guide : GuideData }> );
	Zone( ? bgColor : Null<Int>, ? ref : Null<String>, ? rows : Null<String>, ? columns : Null<String>, ? zones : Null<Array<DisplayData>> );
	Menu( ? bookmark : Null<WidgetContainerData>, ? orientation : String, ? levelDisplays : StringMap<MenuLevel>, ? xBase : Null<Float>, ? yBase : Null<Float> );
	Notebook;
}

typedef DisplayData = {

	var type : DisplayType;
	@:optional var x : Null<Float> = null;
	@:optional var y : Null<Float> = null;
	@:optional var width : Null<Float> = null;
	@:optional var height : Null<Float> = null;
	@:optional var spritesheets : Null<StringMap<TilesheetEx>>; // TODO set in second step
	@:optional var spritesheetsSrc : StringMap<String>;
	@:optional var transitionIn : Null<String>;
	@:optional var transitionOut : Null<String>;
	@:optional var layout : Null<String>;
	@:optional var filters : Null<String>;
	@:optional var timelines : StringMap<{ ref : String, elements : Array<{ ref : String, transition : String, delay : Float }> }>;
	@:optional var displays : StringMap<ElementData>;
	@:optional var layers : Null<StringMap<TileLayer>>; // set in second step
	@:optional var layersSrc : StringMap<String>;
}

class Display extends Sprite {

	/**
	 * Never instanciated directly (only in sub-classes)
	 */
	private function new() {

		super();
		
		this.displays = new StringMap();
		this.spritesheets = new StringMap();
		this.textGroups = new StringMap();
		this.buttonGroups = new StringMap();
		this.layers = new StringMap();
		this.renderLayers = new Map();
		this.scrollBars = new StringMap();
        this.timelines = new StringMap();
		this.dynamicFields = new Array();
		this.displayTemplates = new StringMap();

		addEventListener(Event.ENTER_FRAME, checkRender);
	}

	// Should not be written. Can't be inlined because of inheritance
	private var groupMenu : String = "menu";
	private var groupNotebook : String = "notebook";
	/**
    * All the spritesheets used here
    **/
	public var spritesheets : StringMap<TilesheetEx>;

	/**
    * Transition to play at the beginning of the part
    **/
	public var transitionIn (default, default) : String;

	/**
    * Transition to play at the end of the part
    **/
	public var transitionOut (default, default) : String;

	/**
	* Layout where to display this widget
	**/
	public var layout (default, default) : String;

	/**
	* Fields with dynamic content that need to be update while loading a new part
	**/
	public var dynamicFields (default, null) : Array<{field: ScrollPanel, content: String}>;

	/**
	* Map for layer render needed
	**/
	public var renderLayers (default, null) : Map<TileLayer, Bool>;

	/**
	* Scroll bars
	**/
	public var scrollBars (default, null) : StringMap<ScrollBar>;

	private var displays : StringMap<Widget>;
	private var zIndex : Int = 0;
	private var layers : StringMap<TileLayer>;

	private var totalSpriteSheets : Int = 0;
//	private var textGroups:Map<String, Map<String, {obj:Fast, z:Int}>>;
	private var textGroups : StringMap<StringMap<{ obj : ElementData, z : Int }>>; // ??? don't understand the use of it
	private var buttonGroups : StringMap<GenericStack<DefaultButton>>;
	private var displayTemplates : StringMap<Template>;
	private var timelines : StringMap<Timeline>;

	var data : Null<DisplayData> = null;

	///
	// API
	//

	//public function parseContent(content:Xml):Void
	public function setContent(d : DisplayData) : Void {

		this.data = d;

		d.x != null ? x = d.x;
		d.y != null ? y = d.y;
		d.width != null && d.height != null ? DisplayUtils.initSprite(this, d.width, d.height, 0, 0.001);

		for (sk in d.spritesheets.keys) {

			var layer = new TileLayer(d.spritesheets.get(sk));
			layers.set(sk, layer);
			addChild(layer.view);
		}
		spritesheets = d.spritesheets;

// FIXME		var uiLayer = new TileLayer(UiFactory.tilesheet);
// FIXME		layers.set("ui", uiLayer);
// FIXME		addChild(uiLayer.view);

		createDisplay(d);

		if (d.transitionIn != null) {

			transitionIn = d.transitionIn;

			addEventListener(Event.ADDED_TO_STAGE, function(e){

					TweenManager.applyTransition(this, transitionIn);

				});
		}
		if (d.transitionOut != null) {

			transitionOut = d.transitionOut;
		}
		if (d.layout != null) {

			layout = d.layout;
		}
		if (d.filters != null) {

// FIXME			filters = FilterManager.getFilter(d.filters);
		}
// FIXME		ResizeManager.instance.onResize();
	}

	public function getLayer(id : String) : TileLayer {

		return layers.get(id);
	}


	///
	// INTERNALS
	//

	private function createDisplay(d : DisplayData) : Void {

		for (c in d.displays.keys) {

			createElement(d.displays.get(c), c);
		}
		for (t in d.timelines) {

			var timeline = new Timeline(t.ref);

			for (e in t.elements) {

				// Creating mock widget for dynamic timeline
				if (e.ref.startsWith("$")) {

					var mock = new Image();
					mock.ref = e.ref;
					timeline.addElement(mock, e.transition, e.delay);
				
				} else if(!displays.exists(e.ref)) {

					throw "[Display] Can't add unexisting widget '"+e.ref+"' in timeline '"+t.ref+"'.";
				
				} else {

					timeline.addElement(displays.get(e.ref), e.transition, e.delay);
				}
			}
			timelines.set(t.ref, timeline);
		}
		for (elem in displays) {

			if (Std.is(elem, DefaultButton)) { // could be avoided / improved with a collection of enums

				cast(elem,DefaultButton).initStates(timelines);
			}
		}
	}




typedef DisplayData = {

	var x : Null<Float> = null;
	var y : Null<Float> = null;
	var width : Null<Float> = null;
	var height : Null<Float> = null;
	var spritesheets : Null<StringMap<TilesheetEx>>; // set in second step
	var spritesheetsSrc : StringMap<String>;
	var transitionIn : Null<String>;
	var transitionOut : Null<String>;
	var layout : Null<String>;
	var filters : Null<String>;
	var timelines : StringMap<{ ref : String, elements : Array<{ ref : String, transition : String, delay : Float }> }>;
	var displays : StringMap<ElementData>;
	var layers : Null<StringMap<TileLayer>>; // set in second step
	var layersSrc : StringMap<String>;
}

	//private function createElement(elemNode:Fast):Widget
	private function createElement(e : ElementData, r : String) : Widget {

		switch (e) {

			case TextGroup(d):

				createTextGroup(r, d);
				return null;

			case Image(d):

				return createImage(r, d);

			case TileImage(d):

				return createTileImage(r, d);

			case CharacterData(d):

				return createCharacter(r, d);

			case DefaultButton(d):

				return createButton(r, d);

			case ScrollPanel(d):

				return createText(r, d);

			case VideoPlayer(d):

				return createVideo(r, d);

			case SoundPlayer(d):

				return createSound(r, d);

			case ScrollBar(d):

				return createScrollBar(r, d);

			case SimpleContainer(d):

				var div = new SimpleContainer(d);
				
				addElement(div, r);
				
				return div;

			case ChronoCircle(d):

	            var timer = new ChronoCircle(d);

	            addElement(timer, r);

				return timer;

			case Template(d : { data : ElementData, validation : Null<String> }):

				displayTemplates.set(r, { data: d, z: zIndex++});

				return null;

/* FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME 

			case "include" :
				if(!DisplayUtils.templates.exists(elemNode.att.ref))
					throw "[KpDisplay] There is no template '"+elemNode.att.ref+"'.";
				var tmpXml = Xml.parse(DisplayUtils.templates.get(elemNode.att.ref).toString()).firstElement();
				for(att in elemNode.x.attributes()){
					if(att != "ref")
						tmpXml.set(att, elemNode.x.get(att));
				}
				createElement(new Fast(tmpXml));
*/
		}
	}

	private function createScrollBar(r : String, d : { width : Float, bgColor : Null<String>, cursorColor : Null<String>, bgTile : Null<String>, tile : String, spritesheet : Null<String>, cursor9Grid : Array<Float>, bg9Grid : Null<Array<Float>> }) : Widget {

		var tilesheet = d.spritesheet != null ? spritesheets.get(d.spritesheet) : null; // FIXME UiFactory.tilesheet;

		var cursor9Grid : Rectangle = new Rectangle(d.cursor9Grid[0], d.cursor9Grid[1], d.cursor9Grid[2], d.cursor9Grid[3]);
		
		var bg9Grid : Rectangle;
		
		if (d.bg9Grid != null) {

			bg9Grid = new Rectangle(d.bg9Grid[0], d.bg9Grid[1], d.bg9Grid[2], d.bg9Grid[3]);
		
		} else {

			bg9Grid = cursor9Grid;
		}
		var scroll = new ScrollBar(d.width, tilesheet, d.tile, d.bgTile, cursor9Grid, bg9Grid, d.cursorColor, d.bgColor);

		scrollBars.set(r, scroll);

		return scroll;
	}

    private function createSound(r : String, d : WidgetContainerData) : Widget {

    	switch (d.type) {

    		case SoundPlayer:

				d.tilesheet = d.spritesheetRef != null ? spritesheets.get(d.spritesheetRef) : null;
				var sound = new SoundPlayer(d);
				addElement(sound, r);
				return sound;

    		default: throw "wrong WidgetContainerData type passed to createSound function: " + d.type;
    	}

		return null;
	}

	private function createVideo(r : String, d : WidgetContainerData) : Widget {
#if flash
		switch (d.type) {

			case VideoPlayer(controlsHidden, autoFullscreen):

				d.tilesheet = d.spritesheetRef != null ? spritesheets.get(d.spritesheetRef) : null;
				var video = new VideoPlayer(d);

				addElement(video, r);
				
				return video;

			default: throw "wrong WidgetContainerData type passed to createVideo function: " + d.type;
		}
#end
		return null;
	}

	private function createText(r : String, d : WidgetContainerData) : Widget {

		switch(d.type) {

			case ScrollPanel(styleSheet, style, content, trim):

				var panel = new ScrollPanel(d);

				addElement(panel, r);

				if (content != null && content.startsWith("$")) {

					dynamicFields.push({ field: panel, content: content.substr(1) });
				}
				return panel;

			default: throw "wrong WidgetContainerData type passed to createText function: " + d.type;
		}
		return null;
	}

	//private function createButton(buttonNode : Fast) : Widget {
	private function createButton(r : String, d : WidgetContainerData) : Widget {

		switch (d.type) {

			case DefaultButton(? defaultState : String, ? isToggleEnabled : Bool, ? action : Null<String>, ? group : Null<String>, ? enabled : Bool):
				
				var btn : DefaultButton = new DefaultButton(d);

				if (action != null) {

					setButtonAction(btn, action);
				}
				if (group != null) {

					if (buttonGroups.exists(group)) {

						buttonGroups.get(group).add(btn);
					
					} else {

						var stack : GenericStack<DefaultButton> = new GenericStack();
						stack.add(btn);
						buttonGroups.set(group, stack);
					}
				}
				if (btn.group != null) {

					btn.addEventListener(ButtonActionEvent.TOGGLE, onButtonToggle);
				}

				addElement(btn, r);
				
				return btn;

			default: throw "wrong WidgetContainerData type passed to createButton function: "+d.type;
		}
		return null;
	}

	private function createCharacter(r : String, d : CharacterData) : Widget {

		var c : CharacterDisplay = new CharacterDisplay(d);
		
		addElement(c, r);
		
		return c;
	}

	//private function createImage(itemNode:Fast):Widget // TODO check overrides
	private function createTileImage(r : String, d : TileImageData) : Widget {

		if (!layers.exists(d.tilesheetName)) {

// FIXME			var layer = new TileLayer(UiFactory.tilesheet);
// FIXME			layers.set(d.tilesheetName, layer);
		}
		var img = new TileImage(d);
		
		addElement(img, r, d.isBackground);
		
		return img;
	}
	private function createImage(r : String, d : ImageData) : Widget {

		d.tilesheet = spritesheets.get(d.tilesheetRef);
		var img =  new Image(d);

		addElement(img, r, d.isBackground);
		
		return img;
	}

	//private function createTextGroup(textNode:Fast):Void
	private function createTextGroup(r : String, d : { data : StringMap<{ obj : ElementData, z : Int }> }) : Void {

		for (e in d.data) {

			createElement(e.obj);
		}
		textGroups.set(r, d.data);
	}

	//private function addElement(elem:Widget, node:Fast):Void
	private function addElement(elem : Widget, ref : String, ? isBackground : Bool = false) : Void {

		if (isBackground) {

			elem.zz = 0;
		
		} else {

			elem.zz = zIndex;
		}
		displays.set(ref, elem);

// FIXME		ResizeManager.instance.addDisplayObjects(elem, node);
		zIndex++;
	}

	private function setButtonAction(button:DefaultButton, action:String):Bool
	{
		var actionSet = true;
		if(action.toLowerCase() == "open_menu"){
			button.buttonAction = function(?target){
				GameManager.instance.displayContextual(MenuDisplay.instance, MenuDisplay.instance.layout);
			}
			if(!buttonGroups.exists(groupMenu))
				buttonGroups.set(groupMenu, new GenericStack<DefaultButton>());
			buttonGroups.get(groupMenu).add(button);
		}
		else if(action.toLowerCase() == "open_inventory"){
			button.buttonAction = function(?target){
				GameManager.instance.displayContextual(NotebookDisplay.instance, NotebookDisplay.instance.layout);
			}
			if(!buttonGroups.exists(groupNotebook))
				buttonGroups.set(groupNotebook, new GenericStack<DefaultButton>());
			buttonGroups.get(groupNotebook).add(button);
		}
		else if(action.toLowerCase() == "close_menu")
			button.buttonAction = function(?target){
				GameManager.instance.hideContextual(MenuDisplay.instance);
			}
		else if(action.toLowerCase() == ButtonActionEvent.QUIT)
			button.buttonAction = quit;
		else
			actionSet = false;

		return actionSet;
    }

	private function onButtonToggle(e:ButtonActionEvent):Void
	{
		var button = cast(e.target, DefaultButton);
		for(b in buttonGroups.get(button.group)){
			if(b != button)
				b.toggle(button.toggleState != "active");
		}
	}

	private function checkRender(e:Event):Void
	{
		for(layer in renderLayers.keys()){
			if(renderLayers.get(layer)){
				layer.render();
				renderLayers.set(layer, false);
			}
		}
	}

	private inline function sortDisplayObjects(x:Widget, y:Widget):Int
	{
		if(x.zz < y.zz)
			return -1;
		else if(x.zz > y.zz)
			return 1;
		else
			return 0;
	}

	private inline function quit(?target: DefaultButton):Void
	{
// FIXME		GameManager.instance.quitGame();
	}
}
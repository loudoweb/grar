package grar.view.part;

import grar.view.component.Widget;
import grar.view.component.Image;
import grar.view.component.container.BoxDisplay;
import grar.view.component.container.ScrollPanel;
import grar.view.component.container.DefaultButton;

import grar.view.part.PartDisplay;

import com.knowledgeplayers.grar.localisation.Localiser; // FIXME

import grar.model.part.Part;
import grar.model.part.Item;
import grar.model.part.Pattern;
import grar.model.part.strip.pattern.BoxPattern;
import grar.model.part.TextItem;


import flash.display.DisplayObject;

/**
 * Display for the strip parts, like a comic
 */
class StripDisplay extends PartDisplay {

	public function new(part : Part) {

		super(part);

		boxes = new StringMap();
	}

	private var boxes : StringMap<BoxDisplay>;
	private var currentBox : BoxPattern;
	private var currentBoxItem : Item;


	///
	// API
	//

	override public function next(?target: DefaultButton):Void
	{
		if(Lambda.count(currentBox.buttons) == 0)
			startPattern(currentBox);
		else
			exitPart();
	}


	///
	// INTERNALS
	//

	override private function createDisplay():Void
	{
		super.createDisplay();

		for(elem in part.elements){
			if(elem.isText()){
				addChild(displays.get(cast(elem, TextItem).ref));
				for(image in cast(elem, TextItem).images)
					addChild(displays.get(image));
			}
		}
	}

	//override private function createElement(elemNode:Fast):Widget
	override private function createElement(e : ElementData, r : String) : Widget {

		var elem : Widget = super.createElement(e, r);

		switch(e) {

			case BoxDisplay(d):

				d.tilesheet = spritesheets.get(d.spritesheetRef);
				elem = new BoxDisplay(d);

			default: // nothing
		}
		return elem;
	}

	override private function startPattern(pattern:Pattern):Void
	{
		super.startPattern(pattern);
		currentBox = cast(pattern, BoxPattern);

		var nextItem: Item = pattern.getNextItem();
		if(nextItem != null){
			currentBoxItem = nextItem;
			setupItem(nextItem);

			for(token in nextItem.tokens)
				GameManager.instance.activateToken(token);
		}
		else if(currentBox.nextPattern != "")
			goToPattern(currentBox.nextPattern);
	}

	override private function setBackground(background:String):Void
	{
        if (currentBox != null)
		    super.setBackground(currentBox.background);
	}

	override private function setText(item:TextItem, isFirst:Bool = true):Void
	{
		for(elem in part.elements){
			if(elem.isText()){
				var textItem = cast(elem, TextItem);
				cast(displays.get(textItem.ref), ScrollPanel).setContent(Localiser.instance.getItemContent(textItem.content));
			}
		}
		displayPart();
	}

	override private function setupItem(item:Item, ?isFirst:Bool = true):Void
	{
		currentItem = item;
		if(isFirst)
			setBackground(item.background);

		if(item.isText()){
			var text = cast(item, TextItem);
			setSpeaker(text.author, text.transition);
			setText(text, isFirst);
		}
	}

	override private function displayPart():Void
	{
		if(currentBox != null){
	        var box: BoxDisplay = boxes.get(currentBox.id);
			var nextItem: Item = currentBoxItem;
			while(nextItem != null){
				if(nextItem != null){
					box.textFields.get(nextItem.ref).setContent(Localiser.instance.getItemContent(nextItem.content));
					if(Std.is(nextItem, TextItem))
						GameManager.instance.playSound(cast(nextItem, TextItem).sound);
				}

				nextItem = currentBox.getNextItem();
			}
			if(Lambda.count(currentBox.buttons) == 0){
				box.onComplete = onBoxVisible;
				addChild(box);
			}
			else{
				addChild(box);
				for(key in currentBox.buttons.keys()){
					if(!displays.exists(key))
						throw "[StripDisplay] There is no Button with ref \""+key+"\"";
					addChild(displays.get(key));
				}
			}
		}
		else{
			super.displayPart();
			nextElement();
		}
	}

	private function onBoxVisible():Void
	{
		if(Lambda.count(currentBox.buttons) == 0 && currentBox.nextPattern != ""){
			currentBox.restart();
			goToPattern(currentBox.nextPattern);
		}
	}

//	override private function createImage(itemNode:Fast):Widget
	override private function createImage(r : String, d : ImageData) : Widget {

		if (d.isBackground) {

			var img = new Image(itemNode, spritesheets.get(d.tilesheetRef != null ? d.tilesheetRef : "ui"));
			
			addChild(img);
			
			return img;
		
		} else {

			return super.createImage(r, d);
		}

	}
}
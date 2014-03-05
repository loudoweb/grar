package grar.view.part;

import grar.view.component.container.DefaultButton;
import grar.view.component.container.ScrollPanel;
import grar.view.part.PartDisplay;

import grar.model.part.Item;
import grar.model.part.PartElement;
import grar.model.part.Part;
import grar.model.part.dialog.ChoicePattern;
import grar.model.part.Pattern;

import flash.events.Event;
import flash.events.MouseEvent;

/**
 * Display of a dialog
 */

class DialogDisplay extends PartDisplay {

	/**
     * Constructor
     * @param	part : DialogPart to display
     */
	public function new(callbacks : grar.view.DisplayCallbacks, applicationTilesheet : aze.display.TilesheetEx, part : Part) {

		super(callbacks, applicationTilesheet, part);
	}

	/**
	 * Pattern playing
	 **/
	public var currentPattern : Pattern;

	override public function next(? target : DefaultButton) : Void {

// 		GameManager.instance.stopSound();
		onSoundToStop();

		startPattern(currentPattern);
	}

	
	///
	// INTERNALS
	//

	override private function startPattern(pattern:Pattern):Void
	{
		super.startPattern(pattern);

		if(currentPattern != pattern)
			currentPattern = pattern;

		// Check if minimum choices requirements is met
		var exitPattern = false;
		if(Std.is(currentPattern, ChoicePattern)){
			var choicePattern = cast(currentPattern, ChoicePattern);
			// Init button with choice's view state
			for(choice in choicePattern.choices.keys()){
				if(!displaysRefs.exists(choice))
					throw "[DialogDisplay] There is no template for choice named '"+choice+"'.";
				cast(displaysRefs.get(choice), DefaultButton).toggle(!choicePattern.choices.get(choice).viewed);
			}
			if(choicePattern.minimumChoice == choicePattern.numChoices){
				exitPattern = true;
			}
		}

		if(pattern != null){
			var next: Item = pattern.getNextItem();
			if(next != null && !exitPattern){
				crawlTextGroup(next, pattern);
			}
			else if(currentPattern.nextPattern != "")
				goToPattern(currentPattern.nextPattern);
			else{
				var nextIndex = part.getElementIndex(Pattern(currentPattern));
				currentPattern = null;
				nextElement(nextIndex);
			}
		}
		else
			nextElement();
	}

	override private function setButtonAction(button : DefaultButton, action : String) : Bool {

		if (action.toLowerCase() == "goto") {

			button.buttonAction = onChoice;
			button.addEventListener(MouseEvent.MOUSE_OVER, onOverChoice);
			button.addEventListener(MouseEvent.MOUSE_OUT, onOutChoice);

			return true;
		}

		return super.setButtonAction(button, action);
	}

	override private function onVideoComplete(e: Event):Void
	{
		super.onVideoComplete(e);
		next();
	}

	private function onChoice(?choice: DefaultButton):Void
	{
// 		GameManager.instance.stopSound();
		onSoundToStop();

		cast(currentPattern, ChoicePattern).numChoices++;
		var target = cast(currentPattern, ChoicePattern).choices.get(choice.ref).goTo;
		cast(currentPattern, ChoicePattern).choices.get(choice.ref).viewed = true;

		choice.removeEventListener(MouseEvent.MOUSE_OUT, onOutChoice);
		choice.toggle(false);
		
		// Clean tooltip
		onOutChoice(null);
		goToPattern(target);
	}

	private function onOverChoice(e:MouseEvent):Void
	{
		var choiceButton = cast(e.currentTarget, DefaultButton);
		var pattern = cast(currentPattern, ChoicePattern);
		var choice:Choice = null;
		for(key in pattern.choices.keys()){
			if(choiceButton.ref == key)
				choice = pattern.choices.get(key);
		}
		if(choice != null && pattern.tooltipRef != null && choice.toolTip != null){
			if(!displaysRefs.exists(pattern.tooltipRef))
				throw "[DialogDisplay] There is no ToolTip with ref " + pattern.tooltipRef;
			var tooltip = cast(displaysRefs.get(pattern.tooltipRef), ScrollPanel);
			
			if (contains(tooltip)) {
				removeChild(tooltip);
			}
//			var content = Localiser.instance.getItemContent(choice.toolTip);
			var content = onLocalizedContentRequest(choice.toolTip);

			tooltip.setContent(content);

			var i:Int = 0;
			while(!Std.is(getChildAt(i), DefaultButton)){
				i++;
			}

// 			TweenManager.applyTransition(tooltip, pattern.tooltipTransition);
			onTransitionRequest(tooltip, pattern.tooltipTransition);

			addChildAt(tooltip, i);
		}
		else{
			removeEventListener(MouseEvent.MOUSE_OVER, onOverChoice);
			removeEventListener(MouseEvent.MOUSE_OUT, onOutChoice);
		}
	}

	private function onOutChoice(e:MouseEvent):Void
	{
		var pattern = cast(currentPattern, ChoicePattern);
		if(pattern.tooltipRef != null)
			removeChild(displaysRefs.get(pattern.tooltipRef));
	}
}
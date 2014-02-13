package com.knowledgeplayers.grar.structure.part;

import com.knowledgeplayers.grar.factory.ItemFactory;
import com.knowledgeplayers.grar.display.GameManager;
import com.knowledgeplayers.grar.util.ParseUtils;
import com.knowledgeplayers.grar.structure.part.Button;
import haxe.xml.Fast;

using StringTools;

class ActivityPart extends StructurePart
{

	/**
	* Rules of this activity
	**/
	public var rules (default, null): Map<String, Rule>;

	public var globalImages (default, default):List<String>;

	/**
	* Groups of input in this activity
	**/
	private var groups: Array<Group>;
	private var groupIndex: Int;
	private var numRightAnswers:Int;

	public function new()
	{
		super();
		groups = new Array<Group>();
		rules = new Map<String, Rule>();
		globalImages = new List<String>();
		groupIndex = -1;
		numRightAnswers = 0;
	}

	public inline function hasNextGroup():Bool
	{
		return groupIndex < groups.length-1;
	}

	public inline function getNextGroup():Group
	{
		return groups[++groupIndex];
	}

	public function getRulesByType(type: String, ?group: Group):Array<Rule>
	{
		var selectedRules = new Array<Rule>();
		var rulesSet = new Map<String, Rule>();
		if(group != null && group.rules != null){
			for(id in group.rules)
				if(rules.exists(id))
					rulesSet.set(id, rules.get(id));
		}
		else
			rulesSet = rules;
		for(rule in rulesSet){
			if(rule.type == type.toLowerCase()){
				selectedRules.push(rule);
			}
		}
		return selectedRules;
	}

	public function validate(input: Input, value: String): Bool
	{
		if(input.values.length == 1 && Std.parseInt(input.values[0]) != null){
			// Init score to 0
			if(score == -1)
				score = 0;
			score += Std.parseInt(input.values[0]);
			return true;
		}
		else{
			var i = 0;
			while(i < input.values.length && input.values[i] != value)
				i++;
			var result = i != input.values.length;
			if(result)
				numRightAnswers++;
			input.selected = value == "true";
			return result;
		}
	}

	/**
	* End an activity
	* @return the id of the next Part if there is a threshold. If there is none, return null
	**/
	public function endActivity():String
	{
		// Score wasn't set before, take good answers percentage
		if(score == -1)
			score = Math.round(numRightAnswers * 100 / groups[groupIndex].inputs.length);
		var contextuals = getRulesByType("contextual");
		for(rule in contextuals){
			if(rule.value == "addtonotebook"){
				var currentGroup = groups[groupIndex];
				var inputs = currentGroup.inputs;
				if(currentGroup.groups != null){
					for(group in currentGroup.groups){
						inputs.concat(group.inputs);
					}
				}
				for(input in inputs){
					if(input.selected)
						GameManager.instance.activateToken(input.id);
				}
			}
		}

		// Reset inputs
		for(group in groups){
			for(input in group.inputs)
				input.selected = false;
		}

		isDone = true;
		var i = 0;
		while(i < parent.elements.length && parent.elements[i].id != id)
			i++;
		if(i == parent.elements.length)
			parent.isDone = true;

		var idNext: String = null;
		var thresholds = getRulesByType("threshold");
		if(thresholds.length == 0){
			getNextElement();
		}
		else{
			thresholds.sort(function(t1: Rule, t2: Rule){
				if(Std.parseInt(t1.value) > Std.parseInt(t2.value))
					return -1;
				else
					return 1;
			});
			var i = 0;
			// Search the highest threshold inferior or equal the score
			while(i < thresholds.length && score < Std.parseInt(thresholds[i].value))
				i++;
			if(i == thresholds.length)
				throw "[ActivityPart] You must have a threshold set to 0.";
			idNext = thresholds[i].id;
		}

		return idNext;
	}

	override public function restart():Void
	{
		super.restart();
		groupIndex = -1;
	}

	override public function toString():String
	{
		return 'ref: $ref, groups: $groups, rules: $rules';
	}

	override public function isActivity():Bool
	{
		return true;
	}

	// Privates

	override private function parseContent(content:Xml):Void
	{
		super.parseContent(content);

		var partFast:Fast = (content.nodeType == Xml.Element && content.nodeName == "Part") ? new Fast(content) : new Fast(content).node.Part;
		for(child in partFast.elements){
			switch(child.name.toLowerCase()){
				case "group":
					var group: Group = createGroup(child);
					groups.push(group);

				case "rule":
					var rule: Rule = {id: child.att.id, type: child.att.type.toLowerCase(), value: child.att.value.toLowerCase()};
					rules.set(rule.id, rule);
				case "image": globalImages.add(child.att.ref);
			}
		}
		// If no rules has been set on a group, all applies
		for(group in groups){
			if(group.rules != null){
				for(rule in rules)
					group.rules.push(rule.id);
			}
		}

		// Ordering Inputs
		var orderingRules = getRulesByType("ordering");
		if(orderingRules.length > 1)
			throw "[ActivityPart] Multiple ordering rules in activity '"+id+"'. Pick only one!";
		if(orderingRules.length == 1){
			if(orderingRules[0].value == "shuffle"){
				for(group in groups){
					var inputs: Array<Input> =  group.inputs;
					for(i in 0...inputs.length){
						var rand = Math.floor(Math.random()*inputs.length);
						var tmp = inputs[i];
						inputs[i] = inputs[rand];
						inputs[rand] = tmp;
					}
				}
			}
		}
	}

	private function createInput(xml:Fast, ?group: Group):Input
	{
		var values;
		if(xml.has.values)
			values = ParseUtils.parseListOfValues(xml.att.values);
		else
			values = new Array<String>();
		return {id: xml.att.id, ref: xml.att.ref, content: ParseUtils.parseHash(xml.att.content), values: values, selected: false, group: group};
	}

	private inline function createGroup(xml: Fast): Group
	{
		var rules: Array<String> = null;
		if(xml.has.rules){
			rules = ParseUtils.parseListOfValues(xml.att.rules);
		}
		var group: Group = {id: xml.att.id, ref: xml.att.ref, rules: rules, groups: new Array<Group>(), inputs: new Array<Input>(), items: new Array<Item>(), buttons: new Array<Button>()};
		for(elem in xml.elements){
			switch(elem.name.toLowerCase()){
				case "group":   group.groups.push(createGroup(elem));
				case "input":   group.inputs.push(createInput(elem, group));
				case "button":
					var content = null;
					if(elem.has.content)
						content = ParseUtils.parseHash(elem.att.content);
					group.buttons.push({ref: elem.att.ref, content: content});
				default:        group.items.push(ItemFactory.createItemFromXml(elem));

			}
		}

		return group;
	}

	private function getAllInputs():Array<Input>
	{
		var inputsGroup = new Array<Input>();
		for(group in groups)
			inputsGroup = inputsGroup.concat(group.inputs);
		return inputsGroup;
	}
}

typedef Group = {
	var id: String;
	var ref: String;
	var rules: Array<String>;
	@:optional var groups: Array<Dynamic>;
	@:optional var inputs: Array<Input>;
	@:optional var items: Array<Item>;
	@:optional var buttons: Array<Button>;
}

typedef Rule = {
	var id: String;
	var type: String;
	var value: String;
}

typedef Input = {
	var id: String;
	var ref: String;
	var content: Map<String, String>;
	var values: Array<String>;
	var selected: Bool;
	@:optional var group: Group;
}


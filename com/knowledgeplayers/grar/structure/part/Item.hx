package com.knowledgeplayers.grar.structure.part;

import com.knowledgeplayers.grar.util.ParseUtils;
import haxe.xml.Fast;

class Item implements PartElement {
	/**
	* @inherits
	**/
	public var id (default, null):String;

	/**
     * Content of the item
     */
	public var content (default, default):String;

	/**
    * Background when the item is displayed
    **/
	public var background (default, default):String;

	/**
    * ID of the button that will appear with this item
    **/
	public var button (default, default): Map<String, Map<String, String>>;

	/**
    * Unique ref that will match the display
    **/
	public var ref (default, default):String;

	/**
    * Reference to the token in this item
    **/
	public var token(default, null):String;

	public var endScreen (default, null):Bool = false;

	public var timelineIn (default, default):String;
	public var timelineOut (default, default):String;

	/**
     * Constructor
     * @param	xml : fast xml node with structure info
     * @param	content : text of the item
     */
	private function new(?xml:Fast, content:String = "")
	{
		if(xml != null){
			if(xml.has.content)
				this.content = xml.att.content;
			if(xml.has.ref)
				ref = xml.att.ref;
			if(xml.has.background)
				background = xml.att.background;
			if(xml.has.timelineIn)
				timelineIn = xml.att.timelineIn;
			if(xml.has.timelineOut)
				timelineOut = xml.att.timelineOut;
			var tokens = new StringBuf();
			for(node in xml.nodes.Token){
				tokens.add(node.att.ref);
				tokens.add(",");
			}
			token = tokens.toString();
			token = token.substr(0, token.length-1);
            button = new Map<String, Map<String, String>>();

            for(elem in xml.nodes.Button){
                button.set(elem.att.ref, ParseUtils.parseButtonContent(elem));
			}
			if(xml.has.endScreen)
				endScreen = xml.att.endScreen == "true";
		}
		else{
			this.content = content;
		}
		id = "";
	}

	/**
     * @return true if the item starts a vertical flow
     */

	public function hasVerticalFlow():Bool
	{
		return false;
	}

	/**
     * @return true if the item starts an activity
     */

	public function hasActivity():Bool
	{
		return false;
	}

	/**
    * @return true
    **/

	public function isText():Bool
	{
		return false;
	}

	/**
    * @return false
    **/

	public function isActivity():Bool
	{
		return false;
	}

	/**
    * @return false
    **/

	public function isPattern():Bool
	{
		return false;
	}

	/**
    * @return false
    **/

	public function isPart():Bool
	{
		return false;
	}

	/**
    * @return false
    **/

	public function isVideo():Bool
	{
		return false;
	}

	/**
    * @return false
    **/

	public function isSound():Bool
	{
		return false;
	}
}

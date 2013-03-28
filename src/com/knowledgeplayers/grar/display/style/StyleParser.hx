package com.knowledgeplayers.grar.display.style;

import Hash;
import haxe.xml.Fast;
import nme.Assets;
import nme.display.Bitmap;

/**
 * Parser and manager of the styles
 */
class StyleParser
{

	/**
	 * Instance of the parser
	 */
	public static var instance (getInstance, null): StyleParser;

    /**
    * Path to the current style sheet
    **/
    public static var currentStyleSheet:String;

	private static var styles = new Hash<Hash<Style>>();

    private function new() { }

	/**
	 * @return the instance of the parser
	 */
	public static function getInstance() : StyleParser
	{
		if (instance == null)
			return new StyleParser();
		else
			return instance;
	}

	/**
	 * Parse the style file
	 * @param	xmlContent : content of the style file
	 */
	public function parse(xmlContent : String) : Void
	{
        var stylesheet = new Hash<Style>();
		var xml: Fast = new Fast(Xml.parse(xmlContent)).node.stylesheet;
        var name = xml.att.name;
		for (styleNode in xml.nodes.style) {
			var style: Style = new Style();
			style.name = styleNode.att.name;
			if (styleNode.has.inherit)
				style.inherit(stylesheet.get(styleNode.att.inherit));
			for (child in styleNode.elements) {
				if (child.name.toLowerCase() == "icon"){
					style.icon = Assets.getBitmapData("items/" + child.att.value);
					style.iconPosition = child.att.position.toLowerCase();
				}
				else if (child.name.toLowerCase() == "background") {
					if (Std.parseInt(child.att.value) != null){
						style.background = new Bitmap();
						style.background.opaqueBackground = Std.parseInt(child.att.value);
					}
					else
						style.background = new Bitmap(Assets.getBitmapData("items/" + child.att.value));
				}
				else
					style.addRule(child.name, child.att.value);
			}
			stylesheet.set(styleNode.att.name, style);
		}
        if(Lambda.count(styles) == 0)
            currentStyleSheet = name;
        styles.set(name, stylesheet);
	}

	/**
	 * Get a style by its name. The style file must have been parsed first!
	 * @param	name : Name of the style
	 * @return the style, or null if it doesn't exist
	 */
	public function getStyle(?name: String) : Null<Style>
	{
		if(Lambda.count(styles) == 0)
			throw "No style here. Have you parse a style file ?";
        if(name == null)
            return styles.get(currentStyleSheet).get("text");
		if (StringTools.endsWith(name, "-"))
			return styles.get(currentStyleSheet).get(name + "text");
		else
			return styles.get(currentStyleSheet).get(name);
	}


}
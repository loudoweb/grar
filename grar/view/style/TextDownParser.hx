package grar.view.style;

import js.html.Element;
import js.Browser;
import js.html.ParagraphElement;

using StringTools;

/**
 * Parser for the MarkUp language
 */
class TextDownParser {

	public function new(){ }

	///
	// API
	//

	/**
     * Parse the string for MarkUp
     * @param	text : text to parse
     * @return a sprite with well-formed text
     */
	public function parse(text:String):List<Element>
	{
		var list = new List<Element>();
		// Standardize line endings
		var lineEnding:EReg = ~/(\r)(\n)?|(&#13;)|(&#10;)|(<br\/>)/g;
		var uniformedText = lineEnding.replace(text, "\n");

		for (line in uniformedText.split("\n")) {

			var formattedLine = parseLine(line);
			list.add(formattedLine);
			list.add(Browser.document.createBRElement());
		}
		return list;
	}


	///
	// INTERNALS
	//

	private function parseLine(line : String) : Element {

		var styleName = "";
		var substring:String = line;
		var level = 1;
		var output: Element = null;

		while (substring.charAt(0) == " ") {

			level++;
			substring = substring.substr(1);
		}

		switch (substring.charAt(0)) {

			// Bigger Style
			case "+":

				styleName += "big-";
				substring = substring.substr(1);

			// Smaller Style
			case "-":

				styleName += "small-";
				substring = substring.substr(1);

			// Title style
			case "#":

				styleName += "title";
				substring = substring.substr(1);
				while(substring.charAt(0) == "#"){
					level++;
					substring = substring.substr(1);
				}
				styleName += Std.string(level);

			// Quote Style
			case ">":

				styleName += "quote";
				substring = substring.substr(1);

			// Lists Style
			case "*":

				if(substring.charAt(1) == " " || substring.substr(1).indexOf("*") == -1){
				styleName += "list" + level;
				substring = substring.substr(1);
			}

			// Default Style
			default: substring = line;
		}
		if (styleName == "" && substring.charAt(1) == ".") {

			styleName += "ordered" + level;
			var span = Browser.document.createSpanElement();
			span.innerHTML = substring.substr(0);
			output = Browser.document.createParagraphElement();
			output.appendChild(span);
			substring = substring.substr(2);
		}

		// Custom Style on the whole line.
		var regexStyle:EReg = ~/(\[([^\]]+)\]([^\[]+)\[\/([^\]]+)\])([^[]*)/;

		if (regexStyle.match(substring)) {
			var style = regexStyle.matched(2);
			var span = Browser.document.createSpanElement();
			span.classList.add(style);
			span.textContent = regexStyle.matched(3);
			output = Browser.document.createParagraphElement();
			output.appendChild(span);
			substring = regexStyle.replace(substring, "$5");
		}

		substring = StringTools.ltrim(substring);

		if(styleName.startsWith("title")){
			output = Browser.document.createElement("h"+level);
		}
		else if (styleName != "") {
			output = Browser.document.createParagraphElement();
			output.classList.add(styleName);
		}

		if(output == null)
			output = Browser.document.createParagraphElement();

		output.appendChild(Browser.document.createTextNode(substring));

		return output;
	}
}
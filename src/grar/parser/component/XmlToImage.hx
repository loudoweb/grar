package grar.parser.component;

import grar.view.component.Widget;
import grar.view.component.Image;
import grar.view.component.TileImage;

import grar.parser.component.XmlToWidget;

import grar.util.ParseUtils;

import haxe.xml.Fast;

class XmlToImage {

	static public function parseTileImageData( f : Fast, ? layerRef : Null<String>, visible : Bool = true, ? div : Bool = false ) : TileImageData {

		var tid : TileImageData = { };

		tid.layerRef = layer;
		tid.visible = visible;
		tid.div = div;
		tid.tilesheetName = f.has.spritesheet ? f.att.spritesheet : null;

		tid.id = parseImageData(f);

		return tid;
	}

	static public function parseImageData( f : Fast, ? tilesheetRef : Null<String> ) : ImageData {

		var id : ImageData = { };

		id.wd = XmlToWidget.parseWidgetData(f);
		id.tilesheetRef = tilesheetRef;
		
		if (f != null) {

			//var f : Fast = new Fast(xml);

			if (f.has.vertices) {

				id.vertices = new List();

				ParseUtils.parseListOfValues(f.att.vertices).iter(function(vertex: String){

						var v = vertex.split(";");

						id.vertices.add({x: Std.parseFloat(v[0]), y: Std.parseFloat(v[1])});
					});
			}

			if (f.has.radius) {

				id.radius = ParseUtils.parseListOfFloatValues(f.att.radius);
			}

			if (f.has.width && f.has.height) {

				id.height = Std.parseFloat(f.att.height);
				id.width = Std.parseFloat(f.att.width);
			}

			if (f.has.tile) {

				id.tile = f.att.tile;
			}

			if(f.has.smoothing) {

	            id.smoothing = f.has.smoothing ? f.att.smoothing == "true" : true;
	        }

			if (f.has.mirror) {

				id.mirror = switch (f.att.mirror.toLowerCase()) {

								case "horizontal": 1;

								case "vertical": 2;

								case _ : throw '[KpDisplay] Unsupported mirror $f.att.mirror';
							}
			}

			if (f.has.clip) {

				id.clipOrigin = ParseUtils.parseListOfFloatValues(f.att.clip, ";");
			
			}
		}
		return id;
	}
}
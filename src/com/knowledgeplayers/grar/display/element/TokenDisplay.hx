package com.knowledgeplayers.grar.display.element;


/**
 * Graphic representation of a token of the game
 */

import nme.display.Bitmap;
import com.knowledgeplayers.grar.util.LoadData;
import nme.Lib;
import haxe.xml.Fast;
import aze.display.TileSprite;
import aze.display.TileLayer;
import aze.display.TilesheetEx;
import nme.display.Sprite;

class TokenDisplay extends Sprite {

    private var layer:TileLayer;
    private var img:TileSprite;
/**
* Images of the different tokens
**/
    public var imgsToken:Hash<Bitmap>;

    public function new(spritesheet:TilesheetEx, tileId:String,nodesImg:Fast)
    {
        super();

        layer = new TileLayer(spritesheet);
        img = new TileSprite(tileId);
        imgsToken = new Hash<Bitmap>();

        layer.addChild(img);
        addChild(layer.view);
        layer.render();


        for (img in nodesImg.elements)
            {
                //Lib.trace("img : "+img.att.src);

            var image:Bitmap = new Bitmap(cast(LoadData.getInstance().getElementDisplayInCache(img.att.src), Bitmap).bitmapData);

            image.x = Std.parseFloat(img.att.x);
            image.y = Std.parseFloat(img.att.y);
            image.scaleX = Std.parseFloat(img.att.scale);
            image.scaleY = Std.parseFloat(img.att.scale);

            imgsToken.set(img.att.ref,image);

            }
    }

    public function setScale(scale:Float):Float
    {
        img.scale = scale;
        layer.render();
        return scale;
    }

}
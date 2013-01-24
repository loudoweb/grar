package com.knowledgeplayers.grar.display.activity.scanner;

import Std;
import IntHash;
import Std;
import Std;
import Std;
import Std;
import com.knowledgeplayers.grar.display.component.ScrollPanel;
import Lambda;
import Std;
import Std;
import nme.display.DisplayObject;
import Std;
import nme.Lib;
import nme.display.Sprite;
import nme.display.Bitmap;
import nme.Assets;
import haxe.xml.Fast;
import com.knowledgeplayers.grar.event.PartEvent;
import nme.events.Event;
import com.knowledgeplayers.grar.event.LocaleEvent;
import com.knowledgeplayers.grar.structure.activity.Activity;
import com.knowledgeplayers.grar.structure.activity.scanner.Scanner;
class ScannerDisplay extends ActivityDisplay {

    /**
    * Instance
**/
    public static var instance (getInstance, null): ScannerDisplay;

    /**
    * Model for this display
**/
    public var scanner (default, setModel): Scanner;

    /**
    * The scanner text area
**/
    public var textAreas (default, null): Hash<ScrollPanel>;

    private var pointRadius: Float = 0;
    private var pointGraphics: Hash<String>;
    private var pointZ: Int;
    private var textZone: ScrollPanel;
    private var lineHeight: Float;
    private var depths: IntHash<DisplayObject>;

    /**
    * @return the instance
**/

    public static function getInstance(): ScannerDisplay
    {
        if(instance == null)
            instance = new ScannerDisplay();
        return instance;
    }

    override public function setModel(model: Activity): Scanner
    {
        scanner = cast(model, Scanner);
        scanner.addEventListener(LocaleEvent.LOCALE_LOADED, onModelComplete);
        scanner.addEventListener(Event.COMPLETE, onEndActivity);
        this.model = scanner;
        scanner.loadActivity();

        return scanner;
    }

    override public function setDisplay(display: Fast): Void
    {
        parseContent(display);
    }

    override public function startActivity(): Void
    {
        model.startActivity();
    }

    // Private

    private function onEndActivity(e: Event): Void
    {
        model.endActivity();
        unLoad();
        scanner.removeEventListener(PartEvent.EXIT_PART, onEndActivity);
    }

    private function onModelComplete(e: LocaleEvent): Void
    {
        //TODO +2 temporaire, en attendant la transformation de depths
        for(i in 1...Lambda.count(depths) + 2){
            if(depths.get(i) != null)
                addChild(depths.get(i));
        }
        var yOffset: Float = 0;
        var textSprite = new Sprite();
        for(point in scanner.pointsMap){
            var text = new ScrollPanel(textZone.width, lineHeight);
            text.y = yOffset;
            yOffset += lineHeight;
            textAreas.set(point.content, text);
            textSprite.addChild(text);
            var pointDisplay = new PointDisplay(pointGraphics, pointRadius, point);
            pointDisplay.x = point.x;
            pointDisplay.y = point.y;
            pointDisplay.alpha = scanner.pointVisible ? 1 : 0;
            addChild(pointDisplay);
        }
        textZone.content = textSprite;
        dispatchEvent(new Event(Event.COMPLETE));
    }

    private function parseContent(content: Fast): Void
    {
        var background = new Bitmap(Assets.getBitmapData(content.node.Background.att.Id));
        depths.set(Std.parseInt(content.node.Background.att.Z), background);
        ResizeManager.instance.addDisplayObjects(background, content.node.Background);

        pointGraphics = new Hash<String>();
        for(point in content.nodes.Point){
            if(point.has.Z)
                pointZ = Std.parseInt(point.att.Z);
            if(point.has.Color){
                pointRadius = Std.parseInt(point.att.Radius);
                pointGraphics.set(point.att.State, point.att.Color);
            }
            else
                pointGraphics.set(point.att.State, point.att.Img);
        }

        var text = content.node.Text;
        textZone = new ScrollPanel(Std.parseFloat(text.att.Width), Std.parseFloat(text.att.Height));
        textZone.x = Std.parseFloat(text.att.X);
        textZone.y = Std.parseFloat(text.att.Y);
        textZone.setBackground(text.att.Background);
        lineHeight = Std.parseFloat(text.att.LineHeight);
        depths.set(Std.parseInt(text.att.Z), textZone);
    }

    private function new()
    {
        super();
        depths = new IntHash<DisplayObject>();
        textAreas = new Hash<ScrollPanel>();
    }
}
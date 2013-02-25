package com.knowledgeplayers.grar.display;

import nme.text.TextField;
import nme.display.Stage;
import com.knowledgeplayers.grar.display.layout.Layout;
import haxe.xml.Fast;
import nme.Lib;
import com.knowledgeplayers.grar.util.XmlLoader;
import nme.display.Sprite;


class LayoutDisplay extends Sprite {

    private var layouts: Hash<Layout>;
    private var gameD:GameDisplay;
    private var WIDTH:Int;
    private var HEIGHT:Int;

/**
* Layout Display
**/

    public function new():Void {

    super();
    Lib.trace("LayoutDisplay");
    layouts = new Hash<Layout>();
    WIDTH = Lib.current.stage.stageWidth;
    HEIGHT = Lib.current.stage.stageHeight;

}
    /**
    * Parsing du Xml
    **/
    public function parseXml(xml:Xml):Void{


        var fastXml =new Fast(xml);
        var layoutNode: Fast = fastXml.node.Layouts;
        for (lay in layoutNode.elements)
            {

                var layout:Layout = new Layout(lay);

                layouts.set(lay.att.ref,layout);
            }

    }
    /**
    * Initialisation des éléments
    **/
    public function init(gameD:GameDisplay):Void
    {
        Lib.trace("init"+layouts);
        this.gameD = gameD;

        displayLayout("default");
    }


    /**
    * Affichage des éléments
    **/

    public function displayLayout(_ref:String):Void{


        var rowHeight = 0;
        var sizeTotal = 0;
        var total = 0;
        var totalH:Float = 0;



        for( row in layouts.get(_ref).rows){

            //Lib.trace("row size : "+row.size);
            var text_:TextField = new TextField();
            var rowContainer = new Sprite();

            if (row.size !="*")
                {
                    rowHeight= Std.parseInt(row.size);

                }

            else
            {
                for( row in layouts.get(_ref).rows){
                    if (row.size !="*")
                    {
                        total += Std.parseInt(row.size);
                    }

                    }
               rowHeight=HEIGHT-total;
            }

            text_.text = 'row '+row.size;
            text_.x = 200;
            rowContainer.addChild(text_);
            rowContainer.graphics.beginFill(0xFF0000,.1);
            //rowContainer.graphics.lineStyle(1,0x000000,1);
            rowContainer.graphics.drawRect(0, 0, WIDTH, rowHeight);
            rowContainer.graphics.endFill();

            rowContainer.y = totalH;

            addChild(rowContainer);
            totalH+=rowHeight;




            //Lib.trace("rowContainer.height : "+rowContainer.height);
            //Lib.trace("rowContainer.width : "+rowContainer.width);

            var totalC:Float = 0;
            var percent:Float = 0;
            var totalW:Float = 0;

            for( column in row.columns)
            {
                var text_c:TextField = new TextField();
                text_c.text = 'column '+column.size;
                var columnContainer = new Sprite();
                if(column.size !="*")
                {
                    percent = Std.parseFloat(column.size.split("%")[0])/100;
                    //Lib.trace("percent : "+percent);
                }
                else
                {
                    for( column in row.columns)
                    {
                        var percent = Std.parseInt(column.size.split("%")[0])/100;
                        if(column.size !="*"){
                            totalC = 1-percent;
                            }
                    }
                    percent = totalC;
                }
                Lib.trace("rowContainer.height : "+rowContainer.height);
                columnContainer.graphics.beginFill(0x00FF00,.8);
                columnContainer.graphics.drawRect(0, 0, percent*WIDTH, rowHeight);
                columnContainer.graphics.lineStyle(1,0x000000,1);
                columnContainer.graphics.endFill();

                columnContainer.x = totalW;
                columnContainer.addChild(text_c);
                rowContainer.addChild(columnContainer);
                totalW += columnContainer.width;

                //Lib.trace("columnContainer.height : "+columnContainer.height);
                //Lib.trace("columnContainer.width : "+columnContainer.width);
                //Lib.trace("columnContainer.x : "+columnContainer.x);

                for (zone in column.zones)
                    {
                        var zoneContainer= new Sprite();
                        var text_v:TextField = new TextField();
                        text_v.text = zone.ref;
                        text_v.x=100;
                        zoneContainer.graphics.beginFill(0x0000FF,.3);
                        zoneContainer.graphics.drawRect(0, 0,columnContainer.width, rowHeight);
                        zoneContainer.graphics.endFill();

                        zoneContainer.addChild(text_v);
                        columnContainer.addChild(zoneContainer);


                        //Lib.trace("zoneContainer.height : "+zoneContainer.height);
                        //Lib.trace("zoneContainer.width : "+zoneContainer.width);


                    }
            }
        }

       gameD.addChild(this);
    }


}

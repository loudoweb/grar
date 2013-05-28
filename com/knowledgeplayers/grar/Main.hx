package com.knowledgeplayers.grar;

import nme.events.Event;
import com.knowledgeplayers.grar.event.GameEvent;
import com.knowledgeplayers.grar.display.GameManager;
import nme.Assets;
import com.knowledgeplayers.grar.event.PartEvent;
import com.knowledgeplayers.grar.structure.Game;
import com.knowledgeplayers.grar.structure.KpGame;
import nme.Lib;

class Main {

	private var game:Game;

	public static function main()
	{

		#if ios
		Lib.current.stage.addEventListener(Event.RESIZE, function(e: Event){
			new Main();
		});
	#else
		new Main();
		#end

	}

	public function new()
	{
		// Create a new game
		game = new KpGame();

		game.addEventListener(PartEvent.PART_LOADED, onLoadingComplete);
		game.init(Xml.parse(Assets.getText("structure.xml")));

	}

	private function onLoadingComplete(e:PartEvent):Void
	{
		GameManager.instance.startGame(game);
	}
}



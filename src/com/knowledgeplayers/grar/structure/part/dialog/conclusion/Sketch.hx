package com.knowledgeplayers.grar.structure.part.dialog.conclusion;

import nme.display.Sprite;

class Sketch extends ConclusionActivity {
    private var animation: Sprite;

    public function new()
    {
        super();
    }

    override function finishWithFetch(): Bool
    {
        return false;
    }
}
package grar.model.part.item;

import grar.model.part.item.Item;

class GroupItem{

	public var elements (default, default):List<Item>;

	public function new(){
		elements = new List<Item>();
	}
}
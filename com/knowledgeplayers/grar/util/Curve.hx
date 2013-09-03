package com.knowledgeplayers.grar.util;

import com.knowledgeplayers.grar.util.MathUtils;
import haxe.ds.GenericStack;
import nme.display.DisplayObject;
import nme.geom.Point;

/**
* Utility to place items on a curve
**/
class Curve {
	/**
	* Upper value of the angle defining the curve
	**/
	public var maxAngle (default, default):Float;
	/**
	* Lesser value of the angle defining the curve
	**/
	public var minAngle (default, default):Float;
	/**
	* Center of the curve
	**/
	public var center (default, default):Point;
	/**
	* Radius of the curve
	**/
	public var radius (default, default):Float;

	private var objects: Array<DisplayObject>;
	//private var objToAngles : Array<{obj: DisplayObject, angle: Float}>;
	private var objToAngles : Map<DisplayObject, Float>;

	public function new(center: Point, radius: Float = 1, minAngle: Float = 0, maxAngle: Float = 360)
	{
		this.center = center;
		this.radius = radius;
		this.minAngle = minAngle;
		this.maxAngle = maxAngle;

		objects = new Array<DisplayObject>();
		objToAngles = new Map<DisplayObject, Float>();
	}

	public function add(object:DisplayObject, withTween: Bool = true):DisplayObject
	{
		objects.push(object);
		//objToAngles = new Array<{obj: DisplayObject, angle: Float}>();
		var angle = (maxAngle - minAngle)/(2*objects.length);
		for(i in 0...objects.length){
			var a = MathUtils.degreeToRad(angle+(angle*2*i)+minAngle);
			objects[i].x = Math.cos(a)*radius + center.x;
			objects[i].y = Math.sin(a)*radius + center.y;
			//objToAngles.push({obj: objects[i], angle: a});
			objToAngles.set(objects[i], a);
		}
		return object;
	}

	public function getAngle(obj: DisplayObject): Float
	{
		/*if(objToAngles == null)
			throw "[Curve] This curve is empty.";
		var i = 0;
		while(i < objToAngles.length && objToAngles[i].obj != obj)
			i++;
		if(i == objToAngles.length){
			trace("Item '"+obj+"' not found.");
			return 0;
		}
		else
			return objToAngles[i].angle;*/
		return objToAngles[obj];
	}

	public function contains(obj: DisplayObject): Bool
	{
		/*if(objToAngles == null)
			throw "[Curve] This curve is empty.";
		var i = 0;
		while(i < objToAngles.length && objToAngles[i].obj != obj)
			i++;

		return i != objToAngles.length;
		*/
		return objToAngles.exists(obj);
	}

	public function flush():Void
	{
		for(obj in objects)
			obj = null;
		objects = new Array<DisplayObject>();
	}

	public function toString():String
	{
		return 'Curve: center ('+center.x+';'+center.y+') radius '+radius+' angles '+minAngle+'-'+maxAngle+' '+objects.length+' children';
	}
}

package kala.components;

import kala.components.tween.Ease.EaseFunction;
import kala.components.tween.Tween;
import kala.components.Component;
import kala.objects.Object;
import kala.util.types.Pair;
import kha.FastFloat;

class Timer extends Component<Object> {
	
	private var _coolingDownIDs:Array<Pair<Int, Int>> = new Array<Pair<Int, Int>>();
	private var _coolingDownFunctions:Array<Pair<Void->Void, Int>> = new Array<Pair<Void->Void, Int>>();
	
	private var _loopTasks:Array<LoopTask> = new Array<LoopTask>();
	
	override public function reset():Void {
		super.reset();
		
		_coolingDownIDs.splice(0, _coolingDownIDs.length);
		_coolingDownFunctions.splice(0, _coolingDownFunctions.length);
		_loopTasks.splice(0, _loopTasks.length);
	}
	
	override public function addTo(object:Object):Timer {
		super.addTo(object);
		object.onPostUpdate.notifyPrivateCB(this, update);
		return this;
	}

	override public function remove():Void {
		if (object != null) {
			object.onPostUpdate.removePrivateCB(this, update);
		}
		
		super.remove();
	}
	
	public function cooldown(?id:Int, coolingTime:Int, func:Void->Void):Bool {
		if (id == null) {
			for (cdFunc in _coolingDownFunctions) {
				if (cdFunc.a == func) return false;
			}
			
			_coolingDownFunctions.push(new Pair<Void->Void, Int>(func, coolingTime));
			func();
			
			return true;
		}
		
		for (cdID in _coolingDownIDs) {
			if (cdID.a == id) return false;
		}
		
		_coolingDownIDs.push(new Pair<Int, Int>(id, coolingTime));
		func();
		
		return true;
	}
	
	public function delay(delayTime:Int, func:LoopTask->Void):LoopTask {
		var task = new LoopTask(this, delayTime, 1, func, null);
		_loopTasks.push(task);
		return task;
	}
	
	public function loop(duration:Int, execTimes:Int, ?execFirst:Bool = false, onExecute:LoopTask->Void, ?onComplete:LoopTask->Void):LoopTask {
		var task = new LoopTask(this, duration, execTimes, onExecute, onComplete);
		_loopTasks.push(task);
		
		if (execFirst) {
			task.elapsedExecutions++;
			onExecute(task);
		}
		
		return task;
	}
	
	function update(obj:Object, delta:Int):Void {
		var elapsed  = 1;
		if (Kala.deltaTiming) {
			elapsed = delta;
		}

		for (cdID in _coolingDownIDs.copy()) {
			cdID.b -= elapsed ;
			if (cdID.b <= 0) _coolingDownIDs.remove(cdID);
		}
		
		for (cdFunc in _coolingDownFunctions.copy()) {
			cdFunc.b -= elapsed;
			if (cdFunc.b <= 0) _coolingDownFunctions.remove(cdFunc);
		}
		
		for (task in _loopTasks.copy()) {
			task.elapsedTime += elapsed;
			
			if (task.elapsedTime >= task.duration) {
				task.elapsedTime = 0;
				
				task.elapsedExecutions++;
				task.onExecCB(task);
				
				if (task.totalExecutions > 0 && (task.elapsedExecutions == task.totalExecutions)) {
					if (task.onCompleteCB != null) task.onCompleteCB(task);
					task.cancel();
				}
			}
		}
	}
	
}

@:allow(kala.components.Timer)
@:access(kala.components.Timer)
class LoopTask {

	public var onExecCB(default, null):LoopTask->Void;
	public var onCompleteCB(default, null):LoopTask->Void;
	
	public var duration:Int;
	public var elapsedTime(default, null):Int;
	
	public var totalExecutions:UInt;
	public var elapsedExecutions(default, null):UInt;
	
	private var _manager:Timer;
	
	private inline function new(manager:Timer, duration:Int, totalExecutions:UInt, onExecCB:LoopTask->Void, onCompleteCB:LoopTask->Void) {
		this._manager = manager;
		
		this.duration = duration;
		this.totalExecutions = totalExecutions;
		this.onExecCB = onExecCB;
		this.onCompleteCB = onCompleteCB;
		
		elapsedTime = 0;
		elapsedExecutions = 0;
	}
	
	@:extern
	public inline function cancel():Void {
		_manager._loopTasks.remove(this);
		_manager = null;
	}

}

//

@:access(kala.components.tween.Tween)
class TimerEx extends Timer {

	public var _tween:Tween;
	
	public function new() {
		super();
		
		_tween = new Tween();
	}
	
	override public function addTo(object:Object):TimerEx {
		super.addTo(object);
		_tween.object = object;
		return this;
	}
	
	override public function remove():Void {
		super.remove();
		_tween.object = null;
	}
	
	override function update(obj:Object, delta:Int):Void {
		super.update(obj, delta);
		_tween.update(obj, delta);
	}
	
	public function timeline(
		?target:Dynamic, ?ease:EaseFunction, ?onTweenUpdateCB:TweenTask->Void
	):TweenTimeline {
		return _tween.get(target, ease, onTweenUpdateCB);
	}
	
}
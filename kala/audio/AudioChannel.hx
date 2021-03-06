package kala.audio;

class AudioChannel {
	
	public var channel:kha.audio1.AudioChannel;
	
	public var group:AudioGroup;
	public var kept:Bool;
	
	public var finished(get, never):Bool;
	public var length(get, never):Float;
	public var position(get, never):Float;
	
	public var volume(get, set):Float;
	var _volume:Float;
	
	public var muted(default, set):Bool;

	public inline function new(channel:kha.audio1.AudioChannel, group:AudioGroup, kept:Bool) {
		this.channel = channel;
		this.group = group;
		this.kept = kept;
		muted = false;
	}
	
	@:extern
	public inline function play():Void {
		channel.play();
	}
	
	@:extern
	public inline function pause():Void {
		channel.pause();
	}
	
	@:extern
	public inline function stop():Void {
		channel.stop();
		if (!kept && group != null) group.channels.remove(this);
	}
	
	function updateVolume():Void {
		if (muted) {
			channel.volume = 0;
			return;
		} 
	
		if (group != null) {
			if (group.muted) channel.volume = 0;
			else channel.volume = _volume * group.volume;
			return;
		}
		
		channel.volume = _volume;
	}
	
	inline function get_finished():Bool {
		return channel.finished;
	}
	
	inline function get_length():Float {
		return channel.length;
	}
	
	inline function get_position():Float {
		return channel.position;
	}
	
	inline function get_volume():Float {
		return _volume;
	}
	
	inline function set_volume(value:Float):Float {
		_volume = value;
		updateVolume();
		return value;
	}
	
	inline function set_muted(value:Bool):Bool {
		muted = value;
		updateVolume();
		return value;
	}
	
}
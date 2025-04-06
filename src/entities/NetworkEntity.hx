package entities;

@:keepSub
class NetworkEntity implements hxbit.NetworkSerializable extends elk.entity.Entity {
	private var isAlive = false;

	public function new() {
		super();
		enableReplication = true;
	}

	public function onAlive() {
		isAlive = true;
		elk.Elk.instance.entities.add(this);
	}

	public function onUnregister() {}

	public function alive() {
		#if (target.threaded)
		haxe.MainLoop.runInMainThread(onAlive);
		#else
		onAlive();
		#end
	}
}

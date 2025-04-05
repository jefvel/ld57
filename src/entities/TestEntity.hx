package entities;

import gamestates.PlayState;
import cdb.Types.BakedCurve;
import elk.graphics.Sprite;
import hxd.Key;
import h2d.Bitmap;

class TestEntity extends NetworkEntity {
	@:s @:increment(5) @:visible(sameRoom)
	public var posX = 0.0;
	@:s @:increment(5) @:visible(sameRoom)
	public var posY = 0.0;

	var bm : Bitmap = null;
	var lx = 0.;
	var ly = 0.;
	var data : CastleDB.Character;
	var sprite : Sprite;

	var xt : BakedCurve;
	var spdscl = Math.random() * 1.1 + 1.0;

	var idle_squash : BakedCurve;

	public function new(?p) {
		super();
		_init();
	}

	var t = 0.;

	var it = 0.0 + Math.random();

	var frame = 0;

	override function tick(dt : Float) {
		super.tick(dt);
		frame++;
		var scl = Math.sqrt(ax * ax + ay * ay) * 0.3;
		t += dt * scl * 0.002;
		it += dt * 0.3;
		var spd = Math.min(1.0, scl * 0.1);
		if( sprite != null ) {
			// sprite.animation.timeScale = Math.min(1.0, scl * 1.8);
			sprite.rotation = xt.eval((t * 1.3).mod(1)) * spd;
			// sprite.animation.currentFrameIndex = sprite.rotation < 0 ? 0 : 1;
			// sprite.scaleY = 1 + xt.eval((t * 0.4).mod(1)) * 0.5 * spd + idle_squash.eval(it % 1.0) * 0.77;
			// sprite.scaleX = 1 + xt.eval((t * 0.7).mod(1)) * 0.3 * spd;
			x += (posX - x) * 0.2;
			y += (posY - y) * 0.2;
		}

		/*
			var sp = data.MoveSpeed * 10000 * dt * spdscl;
			if( Key.isDown(Key.A) ) {
				ax -= sp;
			}
			if( Key.isDown(Key.D) ) {
				ax += sp;
			}

			if( Key.isDown(Key.W) ) {
				ay -= sp;
			}
			if( Key.isDown(Key.S) ) {
				ay += sp;
			}
		 */

		if( hxbit.NetworkHost.current?.isAuth ) {
			posX += (Math.random() - 0.5) * 2;
			posY += (Math.random() - 0.5) * 2;
		}

		var dSq = hxd.Math.distanceSq(vy, vx);
		var maxSpeed = data.MaxSpeed;
		if( dSq > maxSpeed * maxSpeed ) {
			var d = Math.sqrt(dSq);
			vx /= d;
			vy /= d;
			vx *= maxSpeed;
			vy *= maxSpeed;
		}

		// if( frame % 20 == 0 && Std.random(100) == 5 ) remove();

		if( hxd.Math.distance(lx - x, ly - y) > 22 ) {
			// elk.Elk.instance.sounds.playSound(hxd.Res.sound.click);
			lx = x;
			ly = y;
		}
	}

	override function remove() {
		super.remove();
		if( sprite != null ) sprite.remove();
	}

	function _init() {
		data = CastleDB.character.get(Man);

		friction = 10.;

		t = Math.random() * 30;
		xt = data.curva.bake(20);
		idle_squash = data.IdleSquash.bake(20);

		if( elk.Elk.type == Dedicated ) return;

		sprite = hxd.Res.img.ball.toSprite(gamestates.PlayState.instance.objects);
		sprite.set_origin(0.5, 0.9);
		sprite.animation.progress = Math.random();
		sprite.animation.pause = true;
	}

	override function render() {
		sprite.x = interpX;
		sprite.y = interpY;
		// trace(interpX);
	}

	override function onUnregister() {
		if( sprite != null ) sprite.remove();
	}

	public override function onAlive() {
		super.onAlive();
		reset();
		_init();
		x = posX;
		y = posY;
	}
}

package entities;

import elk.entity.Entity;
import elk.graphics.Sprite;
import gamestates.PlayState;
import h2d.col.Point;
import elk.util.EasedFloat;

class Cursor extends Entity {
	var bmp : Sprite;

	public var owner : net.MultiplayerPlayer = null;

	public var max_speed = 2.0;

	public function new(p, owner) {
		super();
		this.owner = owner;
		init();
	}

	function init() {
		bmp = hxd.Res.img.sword.toSprite(PlayState.instance.container);
		// bmp.originX = bmp.originY = 16;
		x = owner.x;
		y = owner.y;
	}

	override function tick(dt : Float) {
		super.tick(dt);
		if( bmp == null ) return;

		if( owner.roomId != PlayState.cursor?.owner.roomId ) {
			bmp.visible = false;
		} else {
			if( !bmp.visible ) {
				x = owner.x;
				y = owner.y;
			}
			bmp.visible = true;
		}

		if( owner.is_self ) {
			owner.x = owner.local_x;
			owner.y = owner.local_y;
		}

		if( bmp != null ) {
			if( killed || !owner.enableReplication ) {
				bmp.remove();
				return;
			}

			if( owner.is_self && false ) {
				x = owner.local_x;
				y = owner.local_y;
			} else {
				var max_speed = max_speed;
				var p = new h2d.col.Point(owner.x - bmp.x, owner.y - bmp.y);
				var spd = p.length();
				if( spd < max_speed * 5 ) {
					p.scale(max_speed * 0.2);
				} else {
					p.normalize();
					p.scale(max_speed);
				}

				vx += p.x * 0.54;
				vy += p.y * 0.54;
				vx *= 0.6;
				vy *= 0.6;
				p.x = vx;
				p.y = vy;

				p.limitLength(max_speed);
				vx = p.x;
				vy = p.y;

				x += vx;
				y += vy;
			}
		}
	}

	override function render() {
		super.render();
		bmp.x = interpX - f.value * 16;
		bmp.y = interpY - f.value * 16;

		// bmp.setScale(f.value);
	}

	public var killed = false;

	public override function remove() {
		super.remove();
		killed = true;
		bmp.visible = false;
	}

	var f = EasedFloat.elastic(1.0, 0.5);

	public function blink() {
		f.setImmediate(1.3);
		f.value = 1.0;
	}
}

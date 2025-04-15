package entities;

import differ.Collision;
import differ.shapes.Circle;
import differ.shapes.Shape;
import elk.Elk;
import elk.M;
import elk.graphics.Sprite;
import elk.input.Input;
import elk.util.EasedFloat;
import gamestates.PlayState;
import h2d.Bitmap;
import h2d.Graphics;
import h2d.Object;
import h2d.Text;
import hxd.Key;

enum State {
	Idle;
	Dashing;
	Falling;
	Dodging;
	Sliding;
	Dead;
}

class Man extends elk.entity.Entity {
	var sprite : Sprite;

	public var state : State = Idle;

	var direction = 1;

	public var started = false;

	public var onGround = true;

	public var obj : h2d.Object;

	public var light : Object;

	var bigLight : Bitmap;
	var spotLight : Bitmap;

	var par : Object;

	var aliveTime = 0.0;

	var dbug : Graphics;

	var c : elk.castle.CastleDB.Character;

	var timeSinceJump = 0.0;

	var dodge : Sprite;
	var dodging = true;
	var timeSinceDodge = 0.0;
	var dodgeCooldown = 0.0;

	var stoopPower = 0.0;

	var txt : Text;

	public var freeMove = false;

	public var deadTime = 0.0;
	public var dead = false;
	public var evaporated = false;

	var squish = EasedFloat.elastic(1.0, 0.5);
	var sideSquish = EasedFloat.elastic(0, 0.4);
	var slideSound : hxd.snd.Channel;
	var slideTime = 0.0;
	var slideEndMultiplier = 0.1;
	var stooping = false;

	static var jumpHeight = 16.0 * 2;

	static var jumpTimeToPeak = 0.4;
	static var jumpTimeToDescent = 0.3;
	static var jumpLength = 16.0 * 5;

	static var fastJumpTimeToPeak = 0.3;
	static var fastJumpTimeToDescent = 0.3;

	var fastJumpGravity = (2 * jumpHeight) / (fastJumpTimeToPeak * fastJumpTimeToPeak);
	var fastFallGravity = (2 * jumpHeight) / (fastJumpTimeToDescent * fastJumpTimeToDescent);

	var jumpVel = -(2 * jumpHeight) / jumpTimeToPeak;
	var jumpGravity = (2.0 * jumpHeight) / (jumpTimeToPeak * jumpTimeToPeak);
	var fallGravity = (2.0 * jumpHeight) / (jumpTimeToDescent * jumpTimeToDescent);

	var jumpVelX = (jumpLength) / (jumpTimeToPeak + jumpTimeToDescent);

	public var slowdown = EasedFloat.smootherstep_in_out(1.0, 0.02);

	public function new(?p) {
		super();
		par = p;
		slowdown.ignoreTimeScale = true;
		c = elk.castle.CastleDB.character.get(Man);

		dbug = new Graphics(p);

		obj = new Object(p);

		dodge = hxd.Res.img.dodge.toSprite(obj);
		dodge.center_origin();
		dodge.originY += 2;
		dodge.visible = false;

		sprite = hxd.Res.img.man.toSprite(obj);
		sprite.originX = 12;
		sprite.originY = 24;
		sprite.y = 8;
		sprite.animation.play("idle");

		light = new Object();
		light.scale(1.5);
		bigLight = new Bitmap(hxd.Res.img.light.toTile().center(), light);
		bigLight.setScale(1.1);
		bigLight.blendMode = AlphaAdd;
		spotLight = new Bitmap(hxd.Res.img.light.toTile().center(), bigLight);
		spotLight.alpha = 0.0;
		spotLight.blendMode = AlphaAdd;
		var manLight = new Bitmap(hxd.Res.img.manlight.toTile().center(), light);

		txt = new Text(hxd.Res.fonts.marumonica.toFont(), PlayState.instance);
		txt.x = 40;

		PlayState.instance.debug.addRange('slideEnd', slideEndMultiplier, (f) -> slideEndMultiplier = f, 0.0, 1.0);
	}

	override function render() {
		super.render();
		obj.x = Math.round(interpX);
		obj.y = Math.round(interpY);
		light.x = obj.x;
		light.y = obj.y;
		var globPos = obj.localToGlobal();
		// globPos = txt.globalToLocal();
		txt.x = globPos.x + 40;
		txt.y = globPos.y;
	}

	function doDodge() {
		if( dodging || dodgeCooldown > 0 ) {
			return;
		}

		dodging = true;
		sprite.animation.play('air_roll', false, true);
		timeSinceDodge = 0;
		dodgeCooldown = 0.6;

		Elk.instance.sounds.playWobble(hxd.Res.sound.dodge, 0.4);
	}

	public function processPress() {
		if( !onGround ) {
			doDodge();
			return;
		}

		started = true;

		var dashAcc = c.DashPower * direction;
		// ax += dashAcc;
		// vx += c.DashPowerVel * direction;
		// vy -= c.JumpPower;
		vy = jumpVel;
		vx += jumpVelX * direction;

		Elk.instance.sounds.playWobble(hxd.Res.sound.jump, 0.5);

		onGround = false;
		timeSinceJump = 0.0;
	}

	public function dashPressed() {
		return hxd.Key.isPressed(hxd.Key.SPACE) || Key.isPressed(Key.MOUSE_LEFT);
	}

	public function dashDown() {
		return hxd.Key.isDown(hxd.Key.SPACE) || hxd.Key.isDown(hxd.Key.MOUSE_LEFT);
	}

	public function teleport(_x, _y) {
		x = _x;
		y = _y;
	}

	function hitWall() {}

	var checkDistance = 1 / 6.0;

	function collCheck(dx : Float, dy : Float) {
		var velDist = Math.sqrt(dx * dx + dy * dy);
		var checkCount = Math.ceil(velDist * checkDistance);

		dx /= checkCount;
		dy /= checkCount;

		var rx = x;
		var ry = y;

		var speed = Math.sqrt(vx * vx + vy * vy);
		var startVy = vy;

		var touchingGround = false;

		for (i in 0...checkCount) {
			rx += dx;
			ry += dy;

			var col = findCloseTiles(rx, ry, dodging ? 10 : 8);
			if( col == null ) continue;

			rx += col.separationX;
			ry += col.separationY;

			if( col.unitVectorY < -0.5 ) {
				vy *= 0.8;
				ay *= 0.8;
			}

			if( col.unitVectorY <= -0.91 ) {
				touchingGround = true;
			}

			if( vy > 0 && state != Sliding ) {
				if( col.unitVectorY <= -0.91 ) {
					land(rx, ry, Math.abs(startVy));
					return;
				}
			} else if( col.unitVectorY > 0.9 ) {
				if( vy < 0 ) vy *= -0.9;
				if( ay < 0 ) ay *= -0.9;
			}

			if( vx * col.unitVectorX < 0 && Math.abs(col.unitVectorX) > 0.7 && Math.abs(vx) > 0.9 && timeSinceJump > 0.05 ) {
				x = rx;
				y = ry;
				direction = -direction;

				if( dodging ) {
					wallBounce();
				} else {
					vx *= -0.99;
					ax *= -0.99;
					sideSquish.setImmediate(-Math.random() * 0.1 - 0.4);
					sideSquish.value = 0.0;
					Elk.instance.sounds.playWobble(hxd.Res.sound.wallbounce, 0.2);
				}
			}

			break;
		}

		onGround = touchingGround;

		if( state == Sliding && !touchingGround ) {
			stopSliding();
		}

		x = rx;
		y = ry;
	}

	public function evaporate() {
		if( evaporated ) return;
		evaporated = true;
		sprite.animation.play('evap', false, true);
		Elk.instance.sounds.playWobble(hxd.Res.sound.poof, 0.4);
	}

	function wallBounce() {
		vx *= -1.2;
		ax *= -1.2;
		vy = -c.WallJumpVel;
		ay = 0;

		dodge.visible = true;
		dodge.animation.play('dodge', false, true);
		Elk.instance.sounds.playWobble(hxd.Res.sound.hit, 0.4);

		PlayState.instance.freeze(0.12);
		resetDodge();

		sideSquish.setImmediate(-Math.random() * 0.2 - 0.4);
		sideSquish.value = 0.0;
	}

	function findCloseTiles(x : Float, y : Float, r : Float = 8) {
		var levels = PlayState.instance.levels;
		var shapes : Array<Shape> = [];
		for (l in levels) {
			if( l.worldY > y + 40 ) continue;
			if( l.worldY + l.pxHei < y - 40 ) continue;
			// if( l.worldY < y + 32 ) continue;
			// if( l.worldY + l.pxHei > y - 32 ) continue;
			// if( l.worldX > x - 32 ) continue;
			// if( l.worldX + l.pxWid < x + 32 ) continue;

			var g = 5;
			var hg = g >> 1;
			var ground = l.l_Ground;
			var w = ground.gridSize;
			var tx = Math.floor((x - l.worldX) / w);
			var ty = Math.floor((y - l.worldY) / w);
			for (ix in 0...g) {
				var cx = tx + ix - hg;
				if( cx < 0 ) continue;
				if( cx > ground.cWid ) continue;
				for (iy in 0...g) {
					var cy = iy + ty - hg;
					var cell = ground.getInt(cx, cy);
					if( cell != 1 ) continue;

					var cellX = l.worldX + cx * w;
					var cellY = l.worldY + cy * w;
					shapes.push(differ.shapes.Polygon.square(cellX, cellY, w, false));
				}
			}
		}
		var circle = new Circle(x, y, r);
		var colls = Collision.shapeWithShapes(circle, shapes);

		/*
			dbug.clear();
			dbug.lineStyle(1, 0xff00ff);
			dbug.drawCircle(circle.x, circle.y, circle.radius);
		 */

		var closest = null;
		var closestSeparation = 10.0;
		for (col in colls) {
			if( col.overlap < closestSeparation ) {
				closest = col;
				closestSeparation = col.overlap;
			}
		}

		return closest;
	}

	function resetDodge() {
		dodging = false;
		dodgeCooldown = 0.0;
	}

	function land(landX : Float, landY : Float, speed : Float) {
		if( onGround ) return;

		x = landX;
		y = landY;

		var landing = hxd.Res.img.landing.toSprite(par);
		landing.set_origin(0.5, 1);
		landing.x = x;
		landing.y = y + 6;
		landing.animation.play('pop', false, true);
		landing.animation.onEnd = (_) -> landing.remove();

		if( dodging ) {
			resetDodge();

			dodge.animation.play("dodge", false, true);
			dodge.visible = true;

			Elk.instance.sounds.playWobble(hxd.Res.sound.hit, 0.4);
			vy = -c.DashJumpVel * 0.5;
			ay = 0;
			ax *= 0.2;

			var newVx = Math.max(Math.min(Math.abs(vx * 0.7), c.DashJumpVel * 1.2), c.DashJumpVel);

			vx = (newVx * M.sign(vx));

			PlayState.instance.freeze(0.15);
			return;
		}

		onGround = true;

		if( speed >= c.TerminalVel ) {
			die();
			return;
		}

		squish.setImmediate(0.5 - Math.random() * 0.1);
		squish.value = 1.0;
		Elk.instance.sounds.playWobble(hxd.Res.sound.land, 0.2);

		if( dashDown() ) {
			startSliding();
			return;
		}

		vx = 0;
		vy = 0;
		ax = 0;
		ay = 0;
	}

	function startSliding() {
		state = Sliding;
		slideTime = 0.0;
		if( slideSound != null ) slideSound.stop();
		slideSound = elk.Elk.instance.sounds.playWobble(hxd.Res.sound.slide, 0.2, 0.05, true);
		sprite.animation.play('slide_h', true, true);
		var slideYPow = Math.min(Math.abs(vy * 0.6), 200);
		if( Math.abs(vx) < (slideYPow) ) {
			vx = vx > 0 ? (slideYPow) : -(slideYPow);
		}
		vy = 0;
		ay = 0;
		ax = 0;
		trace('started sldign');
	}

	function stopSliding() {
		if( slideSound != null ) slideSound.stop();
		slideSound = null;
		state = Idle;
		squish.setImmediate(1.2 + Math.random() * 0.1);
		squish.value = 1.0;
		vx *= slideEndMultiplier;
		ax *= slideEndMultiplier;
		if( onGround && !dashDown() && slideTime > 0.1 ) {
			processPress();
		} else {
			vx *= 0.1;
		}
	}

	function processSlide(dt : Float) {
		if( state != Sliding ) return;
		slideTime += dt;
		var fricMult = state == Sliding ? 2.0 : 0.0;
		var fric = 1 / (1 + (dt * fricMult));
		vx *= fric;
		if( !dashDown() || Math.abs(vx) < 30 ) {
			stopSliding();
		}
	}

	function die() {
		if( dead ) return;
		slowdown.setImmediate(1.0);
		dead = true;
		sprite.animation.play('dead', false);
		PlayState.instance.onDie();
		elk.Elk.instance.sounds.playWobble(hxd.Res.sound.splat, 0.5);
	}

	function processDead(dt : Float) {
		bigLight.setScale((0.8 - bigLight.scaleX) * 0.9);
		spotLight.scale(0.9);
		deadTime += dt;
	}

	function processMove(dt : Float) {
		var baseFriction = c.Friction;
		if( !onGround ) {
			baseFriction *= 0.5;
		}
		var fric = 1 / (1 + (dt * baseFriction));

		vx += ax * dt;
		vy += ay * dt;

		collCheck(vx * dt, vy * dt);

		vx *= fric;
		vy *= fric;

		ax *= fric;
		ay *= fric;

		/*
			if( onGround && state != Sliding ) {
				ax *= 0.1;
				vx *= 0.1;
			}
		 */
	}

	public function processSlowdown(dt : Float) {
		var shouldSlowdown = false;
		if( vy > c.TerminalVel * 0.95 ) {
			var closeToCandle = false;
			var r = 100.0;

			var cr = r * r;
			var xx = Math.abs(vy) > c.TerminalVel ? 40 : 20;
			var yy = Math.abs(vy) > c.TerminalVel ? 80 : 40;
			for (c in PlayState.candlePositions) {
				if( c.y < y ) continue;
				var dx = c.x - x;
				if( Math.abs(dx) > xx ) continue;

				var dy = c.y - y;
				if( Math.abs(dy) < yy ) {
					closeToCandle = true;
					break;
				}
			}

			if( closeToCandle ) {
				shouldSlowdown = true;
			}
		}

		if( shouldSlowdown ) {
			slowdown.value = 0.2;
		} else {
			slowdown.value = 1.0;
		}
	}

	function endDodge() {
		dodging = false;
	}

	override function remove() {
		super.remove();
		if( slideSound != null ) slideSound.stop();
		slideSound = null;
	}

	public override function tick(dt : Float) {
		if( dead ) {
			processDead(dt);
			return;
		};

		var isPressed = dashDown();
		var justPressed = dashPressed();

		processSlowdown(dt);
		processSlide(dt);

		if( justPressed ) {
			processPress();
		}

		if( !freeMove ) {
			processMove(dt);
		} else {
			var dd = Input.getVector(Key.A, Key.D, Key.W, Key.S);
			x += dd.x * 5;
			y += dd.y * 5;
		}

		var speed = Math.sqrt(vx * vx + vy * vy);
		var lethal = vy > c.TerminalVel;

		txt.text = '${Math.round(speed)}, $lethal,\nvx: ${Math.round(vx)}\nvy: ${Math.round(vy)}\n${Math.round(stoopPower)}\n$timeSinceJump';

		sprite.scaleY = squish.value;

		timeSinceDodge += dt;
		dodgeCooldown -= dt;
		if( timeSinceDodge > c.DodgeDuration ) {
			endDodge();
		}

		aliveTime += dt;
		if( aliveTime < 0.2 ) return;

		sprite.scaleX = direction * (1 + sideSquish.value);

		if( dead ) {
			sprite.animation.play("dead");
		} else if( !onGround ) {
			if( lethal ) {
				sprite.animation.play("fall");
			} else {
				if( dodging && timeSinceDodge < c.DodgeDuration ) {} else if( isPressed && vy > 0.1 ) {
					sprite.animation.play("dash_down");
				} else sprite.animation.play("dash");
			}
			timeSinceJump += dt;
		} else {
			if( state == Sliding ) {
				sprite.animation.play('slide_h');
			} else {
				sprite.animation.play('idle');
			}
		}

		stoopPower *= 0.9;

		var stooping = isPressed && timeSinceJump > 0.1;

		var extraDown = 1.0;
		if( !onGround ) {
			if( stooping ) {
				extraDown = c.ExtraDown;
				vx *= c.ExtraDownFriction;
				if( vy > c.TerminalVel * 0.4 ) {
					stoopPower += (1 - stoopPower) * 0.05;
					if( stoopPower > 0.3 ) startingStoop();
				}
			} else {
				endingStoop();
				var toEase = vy * (stoopPower);
				vy -= toEase * 1.5;
				ay -= toEase * 0.1;
				vx += toEase * direction;
			}
		} else {
			endingStoop();
		}

		// ay += c.Gravity * extraDown;
		if( vy < 0 ) {
			var g = stooping ? fastJumpGravity : jumpGravity;
			vy += g * dt;
		} else {
			var g = stooping ? fastFallGravity : fallGravity;
			vy += g * dt;
		}

		vx = vx.clamp(-c.MaxSpeed, c.MaxSpeed);
		vy = vy.clamp(-c.MaxSpeedV, c.MaxSpeedV);

		processLight();
	}

	function processLight() {
		var l = Math.sqrt(vx * vx + vy * vy);
		var ddx = l > 0 ? vx / l : 0;
		var ddy = l > 0 ? vy / l : 0;
		var dis = M.smootherstep(0.0, 200, l);
		spotLight.x += (ddx * dis * 36 - spotLight.x) * 0.1;
		spotLight.y += (ddy * dis * 36 - spotLight.y) * 0.1;
		spotLight.alpha += (M.smoothstep(0.0, 100, l) * 0.5 - spotLight.alpha) * 0.1;
	}

	function startingStoop() {
		if( stooping ) return;
		stooping = true;
	}

	function endingStoop() {
		if( !stooping ) return;
		stooping = false;
		if( !onGround ) {
			elk.Elk.instance.sounds.playWobble(hxd.Res.sound.stoop_end);
		}
	}
}

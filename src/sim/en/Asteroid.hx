package sim.en;

import box2D.collision.shapes.B2CircleShape;
import h2d.Bitmap;
import box2D.dynamics.B2World;
import box2D.common.math.B2Vec2;
import box2D.dynamics.B2Body;
import box2D.dynamics.B2BodyDef;
import box2D.dynamics.B2BodyType;
import box2D.dynamics.B2Fixture;
import box2D.dynamics.B2FixtureDef;
import box2D.collision.shapes.B2PolygonShape;
import dn.heaps.GamePad.PadKey;
import box2D.common.math.B2Vec2;
import box2D.dynamics.B2Body;

class Asteroid extends Entity {
  var time: Float = 0.;

	var r = 60;

	public function new(b2world, x, y) {
		super(x, y);

		var shape = new B2CircleShape(r/100);

		var fixtureDef = new B2FixtureDef();
		fixtureDef.density = 10;
		fixtureDef.shape = shape;
    fixtureDef.friction = 0;
    fixtureDef.userData = ObjTypes.Asteroid;

		var bodyDef = new B2BodyDef();
		bodyDef.type = B2BodyType.DYNAMIC_BODY;
		bodyDef.position.set(x/100, y/100);

		this.body = b2world.createBody(bodyDef);
		this.body.createFixture(fixtureDef);

		spr.set(Assets.background, Math.random() <= 0.5 ? "asteroid_a" : "asteroid_b");
		spr.setCenterRatio();
		setScale((r<<1) / spr.tile.width);

		this.body.applyTorque(Math.random() - Math.random() * 1000);
	}

	override function update() {
		var theta = body.getAngle();
		var p = body.getPosition();
		setPosPixel(p.x * 100, p.y * 100);
		spr.rotation = body.getAngle();
	}
}
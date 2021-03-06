package sim.en;

import Entity.EntityTypeFlags;
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

class Moon extends Entity {
	var time: Float = 0.;

	public static var Radius = 100;

	static var G = 1;

	public function new(b2world, x, y) {
		super(x, y);
		this.typeFlags |= EntityTypeFlags.MOON;
		this.collider = new h2d.col.Circle(x, y, Radius);

		ignoreGravity = true;

		var shape = new B2CircleShape(Radius/100);

		var fixtureDef = new B2FixtureDef();
		fixtureDef.density = 10;
		fixtureDef.shape = shape;
		fixtureDef.friction = 0;
		fixtureDef.userData = this;

		var bodyDef = new B2BodyDef();
		bodyDef.type = B2BodyType.STATIC_BODY;
		bodyDef.position.set(x/100, y/100);

		this.body = b2world.createBody(bodyDef);
		this.body.createFixture(fixtureDef);

		spr.set(Assets.background, "moon");
		spr.setCenterRatio();
		setScale((Radius*2.0) / spr.tile.width);
	}

	public function applyGravity(otherBody: B2Body) {
		var q = this.body.getPosition();
		var p = otherBody.getPosition();

		var dx = q.x - p.x;
		var dy = q.y - p.y;

		var dsq = dx * dx + dy * dy;
		var vec: B2Vec2 = new B2Vec2(dx, dy);
		vec.normalize();
		vec.multiply(G * otherBody.getMass() / dsq);
		otherBody.applyForce(vec, p);

	}

	override function update() {
		var theta = body.getAngle();
		var p = body.getPosition();
		setPosPixel(p.x * 100, p.y * 100);
		spr.rotation = theta;
	}

}

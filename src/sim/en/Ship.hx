package sim.en;

import sim.components.PowerSupply;
import ShipDefinition.ShipPartDefinition;
import box2D.dynamics.B2FilterData;
import hxd.res.Font;
import hxd.res.DefaultFont;
import h2d.Bitmap;
import box2D.dynamics.B2World;
import box2D.common.math.B2Vec2;
import box2D.dynamics.B2Body;
import box2D.dynamics.B2BodyDef;
import box2D.dynamics.B2BodyType;
import box2D.dynamics.B2Fixture;
import box2D.dynamics.B2FixtureDef;
import box2D.collision.shapes.B2PolygonShape;
import box2D.dynamics.joints.B2WeldJointDef;

class Ship extends Entity {
	var ca:dn.heaps.Controller.ControllerAccess;
	var time:Float = 0.;

	var shipPartWidth = 30;
	var shipPartHeight = 30;
	var shipPartOffsetX = Const.SHIP_WIDTH * 30 * 0.5;
	var shipPartOffsetY = Const.SHIP_HEIGHT * 30 * 0.5;

	var packageLauncherPower = 0.0;
	var packageLauncherPowerModifier = 0.1;

	var shipDefinition: ShipDefinition;
	var visuals: h2d.Object;
	var powerSupply: sim.components.PowerSupply;

	var numPackages = 0;
	var numShields = 0;
	var hullStrength: Float = Const.SHIP_HULL_STRENGTH;
	var mass: Int;
	var forwardBoosters: Array<B2Body> = [];
	var backwardsBoosters: Array<B2Body> = [];
	var leftBoosters: Array<B2Body> = [];
	var rightBoosters: Array<B2Body> = [];
	var forwardLasers: Array<B2Vec2> = [];
	var rearLasers: Array<B2Vec2> = [];
	var leftLasers: Array<B2Vec2> = [];
	var rightLasers: Array<B2Vec2> = [];

	public static var componentShape: B2PolygonShape;
	public static var filterData: B2FilterData;
	public static var b2world: B2World;

	// x and y in sprite coords
	public function new(shipDefinition: ShipDefinition, b2world, x, y) {
		super(x, y);

		this.shipDefinition = shipDefinition;

		visuals = ShipVisuals.createFromDefinition(this.shipDefinition, shipPartWidth, shipPartHeight, spr);

		Ship.b2world = b2world;
		Ship.filterData = new B2FilterData();
		Ship.filterData.groupIndex = -1;

		Ship.componentShape = new B2PolygonShape();
		componentShape.setAsBox(shipPartWidth/200, shipPartHeight/200);

		var fixtureDef = new B2FixtureDef();
		fixtureDef.density = 1;
		fixtureDef.shape = componentShape;
		fixtureDef.friction = 0;
		fixtureDef.filter = Ship.filterData;
		fixtureDef.userData = this;

		var bodyDef = new B2BodyDef();
		bodyDef.type = B2BodyType.DYNAMIC_BODY;
		bodyDef.position.set(x/100, y/100); // div by 100 for b2 coords

		this.body = b2world.createBody(bodyDef);
		this.body.createFixture(fixtureDef);

		var powerCapacity: Float = 0.0;
		var powerRechargeRate: Float = 0.0;

		for(shipPart in shipDefinition.parts) {
			powerCapacity += shipPart.part.power_capacity;
			powerRechargeRate += shipPart.part.recharge_rate;

			trace(shipPart);

			if (shipPart.part.id != Data.ShipPartKind.Core) {
				var bodyPosition = this.body.getPosition();
				var offsetX = shipPart.x * shipPartWidth - shipPartOffsetX + shipPartWidth * 0.5;
				var offsetY = shipPart.y * shipPartHeight - shipPartOffsetY + shipPartHeight * 0.5;
				var bodyDef = new B2BodyDef();
				bodyDef.type = B2BodyType.DYNAMIC_BODY;
				bodyDef.position.set(bodyPosition.x + offsetX/100, bodyPosition.y + offsetY/100);
		
				var componentBody = b2world.createBody(bodyDef);
				componentBody.createFixture(fixtureDef);
				createJoint(componentBody);

				switch shipPart.part.id {
					case Data.ShipPartKind.Booster:
						addBooster(shipPart, componentBody);
					case Data.ShipPartKind.Laser:
						addLaser(shipPart);
					case Data.ShipPartKind.Shield:
						addShield(shipPart);
					case Data.ShipPartKind.SolarPanel:
					case Data.ShipPartKind.Battery:
					case Data.ShipPartKind.Package:
						addPackage(shipPart);
					case Data.ShipPartKind.Core:
				}
			}
		}

		this.powerSupply = new sim.components.PowerSupply(powerCapacity, powerRechargeRate);
		ca = Main.ME.controller.createAccess("hero"); // creates an instance of controller
	}

	function createJoint(componentBody) {
		var jointDef = new B2WeldJointDef();
		jointDef.initialize(this.body, componentBody, this.body.getPosition());
		Ship.b2world.createJoint(jointDef);
	}

	function addBooster(shipPart, boosterBody) {
		switch shipPart.rotation {
			case 0:
				forwardBoosters.push(boosterBody);
			case 90:
				rightBoosters.push(boosterBody);
			case 180:
				backwardsBoosters.push(boosterBody);
			case 270:
				leftBoosters.push(boosterBody);
		}
	}

	function addLaser(shipPart: ShipPartDefinition) {
		var offset = new B2Vec2();
		offset.x += shipPart.x * shipPartWidth - shipPartOffsetX;
		offset.y += shipPart.y * shipPartHeight - shipPartOffsetY;

		switch shipPart.rotation {
			case 0:
				forwardLasers.push(offset);
			case 90:
				leftLasers.push(offset);
			case 180:
				rearLasers.push(offset);
			case 270:
				rightLasers.push(offset);
		}
	}

	function addShield(shipPart: ShipPartDefinition) {
		numShields += 1;
	}

	function addPackage(shipPart: ShipPartDefinition) {
		numPackages += 1;
	}

	override function dispose() {
		super.dispose();
		ca.dispose(); // release on destruction
	}

	public function onCollision () {
		if (cd.has('shipCollision')) {
			return;
		}

		cd.setS('shipCollision', 0.5);

		var damage: Float = 100.0;

		if (numShields >= 1) {
			if (this.powerSupply.consumePower(Data.shipPart.get(Data.ShipPartKind.Shield).power_usage)) {
				damage -= 10.0;
			}
		}

		if (damage > 0) {
			this.hullStrength = Math.max(0, this.hullStrength - damage);
			game.hud.hull.setValue(this.hullStrength / Const.SHIP_HULL_STRENGTH);
			Main.ME.leaderboards.removeFromScore(1);

			if (this.hullStrength <= 0) {
				// POLISH: explosion
				Game.ME.endGame();
			}
		}
	}

	function calculateForce (boosters: Int): Float {
		var powerUsage: Float = boosters * Data.shipPart.get(Data.ShipPartKind.Booster).power_usage;
		var force: Float = 0.0;

		if (this.powerSupply.consumePower(powerUsage)) {
			force = Math.max(0, boosters - (this.mass / 500.0));
		}

		return force;
	}

	override function update() {
		super.update();

		this.powerSupply.update();
		game.hud.powerSupply.setValue(this.powerSupply.getCurrentPowerPercentage());

		var theta = body.getAngle();
		var p = body.getPosition();
		setPosPixel(p.x * 100, p.y * 100);
		spr.rotation = theta;

		var center = this.body.getPosition();

		if (ca.upDown() || ca.isKeyboardDown(hxd.Key.UP)) {
			for (body in forwardBoosters) {
				fireBooster(body, 0);
			}
		}

		if (ca.downDown() || ca.isKeyboardDown(hxd.Key.DOWN)) {
			for (body in backwardsBoosters) {
				fireBooster(body, Math.PI);
			}
		}

		if (ca.leftDown() || ca.isKeyboardDown(hxd.Key.LEFT)) {
			for (body in leftBoosters) {
				fireBooster(body, Math.PI * 3 / 2);
			}
		}
		
		if (ca.rightDown() || ca.isKeyboardDown(hxd.Key.RIGHT)) {
			for (body in rightBoosters) {
				fireBooster(body, Math.PI / 2);
			}
		}


		if (ca.xPressed() && numPackages > 0) {
			if (packageLauncherPower == 0) {
				packageLauncherPower = 1;
			} else {
				launchPackage();
				packageLauncherPower = 0;
			}
		}
	}

	function fireBooster(boosterBody: B2Body, theta) {
		var position = boosterBody.getPosition().copy();
		position.multiply(100);
		var thrustAngle = this.body.getAngle() + Math.PI / 2 + theta;
		Game.ME.fx.spray(position.x, position.y, thrustAngle);
		
		var dir = new B2Vec2(Math.cos(thrustAngle), Math.sin(thrustAngle));
		var forceVec = dir.copy();
		forceVec.multiply(-1 * Const.THRUST_FORCE);

		boosterBody.applyForce(forceVec, boosterBody.getPosition());
	}

	override function fixedUpdate() {
		super.fixedUpdate();
		if (packageLauncherPower != 0) {
			packageLauncherPower += packageLauncherPowerModifier;
			if (packageLauncherPower >= 10) {
				packageLauncherPowerModifier = -0.1;
			}
			if (packageLauncherPower <= 1) {
				packageLauncherPowerModifier = 0.1;
			}
		}

		for (base in this.visuals) {
			for (child in base) {
				for (partDefinition in this.shipDefinition.parts) {
					if (child.name == partDefinition.id) {
						if (partDefinition.part.flags.has(Data.ShipPart_flags.rotateAnimation)) {
							child.rotate(Const.SHIP_PART_ROTATE_SPEED * Const.FPS);
						}
					}
				}
			}
		}
	}

	function launchPackage() {
		numPackages -= 1;

		var packagePosition = body.getPosition();
		var newPackage = new Package(Game.ME.world , cast packagePosition.x * 100, cast packagePosition.y * 100);

		var x = Main.ME.scene.mouseX / 100;
		var y = Main.ME.scene.mouseY / 100;

		var dx = x - packagePosition.x;
		var dy = y - packagePosition.y;

		var vec: B2Vec2 = new B2Vec2(dx, dy);
		vec.normalize();
		vec.multiply(packageLauncherPower);

		newPackage.body.applyForce(vec , packagePosition);
	}
}
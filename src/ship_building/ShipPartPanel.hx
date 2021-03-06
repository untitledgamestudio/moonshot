package ship_building;

import hxd.Res;
import h2d.Bitmap;
import h2d.Flow.FlowLayout;
import h2d.Flow.FlowAlign;
import h2d.Text;

class ShipPartButton extends h2d.Object {
	static var HOVER_COLOR = 0xFFD0D0D0;
	static var HOVER_SIZE = 2.0;
	static var SELECTED_COLOR = 0xFFFFFFFF;
	static var SELECTED_SIZE = 4.0;

	var part: Data.ShipPart;
	var visuals: h2d.Drawable;
	var base: Bitmap;
	var interactive: h2d.Interactive;
	var outline: h2d.filter.Outline;
	var selected: Bool;
	var panel: ShipPartPanel;
	var partWidth: Float;

	public function new (part: Data.ShipPart, width: Float, height: Float, panel: ShipPartPanel) {
		super(panel);
		this.partWidth = width;
		this.part = part;
		this.base = new h2d.Bitmap(Assets.fx.getTile("empty"), this);
		this.base.width = width;
		this.base.height = height;
		this.base.x = width;

		this.visuals = ShipVisuals.create(this.part.id.toString(), this.part, width, height, 0, 0, this);

		addDescriptionText(part.tile_name, 0);
		addDescriptionText("$" + part.cost, 30);
		addDescriptionText(part.mass + "kg", 60);

		this.interactive = new h2d.Interactive(width, height, this.visuals);
		this.outline = new h2d.filter.Outline();
		this.selected = false;
		this.panel = panel;

		this.interactive.onOver = function (event: hxd.Event) {
			if (!this.selected) {
				this.outline.color = HOVER_COLOR;
				this.outline.size = HOVER_SIZE;
				this.visuals.filter = this.outline;
			}
		}

		this.interactive.onOut = function (event: hxd.Event) {
			if (!this.selected) {
				this.visuals.filter = null;
			}
		}

		this.interactive.onPush = function (event: hxd.Event) {
			if (!this.selected) {
				this.outline.color = SELECTED_COLOR;
				this.outline.size = SELECTED_SIZE;
				this.visuals.filter = this.outline;
				this.selected = true;
				this.panel.onSelected(this);
				panel.tooltip.text = ShipPartPanel.getTooltip(part.id);
			}
		}
	}

	public function getPart (): Data.ShipPart {
		return this.part;
	}

	public function deselect () {
		if (this.selected) {
			this.selected = false;
			this.visuals.filter = null;
		}
	}

	public function addDescriptionText(text: String, y: Float) {
		var textObj = new Text(Assets.fontSmall, this.base);
		textObj.text = text;
		textObj.y += y;
	}
}

class ShipPartPanel extends h2d.Flow {
	public static var Instance: ShipPartPanel;
	public var tooltip: Text;

	var selectedPart: ShipPartButton;

	public function new (?parent: h2d.Object) {
		super(parent);
		Instance = this;
	}

	public function addPart (shipPart: Data.ShipPart, width: Float, height: Float): ShipPartButton {
		return new ShipPartButton(shipPart, width, height, this);
	}

	public function getSelectedPart (): Data.ShipPart {
		if (this.selectedPart != null) {
			return this.selectedPart.getPart();
		}

		return null;
	}

	public function onSelected (part: ShipPartButton) {
		Res.audio.select.play(false, 0.1);

		if (part == this.selectedPart) {
			return;
		}

		if (this.selectedPart != null) {
			this.selectedPart.deselect();
		}

		this.selectedPart = part;
	}
	public function addTooltipBox() {
		var flow = new h2d.Flow(Instance);
		flow.paddingTop = 100;
		flow.multiline = true;
		flow.fillWidth = true;
		flow.fillHeight = true;
		flow.horizontalAlign = Middle;
		flow.verticalAlign = Top;
		tooltip = new h2d.Text(Assets.fontSmall, flow);
		tooltip.textAlign = Align.Center;
		tooltip.textColor = 0xBBBBBB;
	}

	public static function getTooltip(type: Data.ShipPartKind) {
		switch (type) {
			case (Data.ShipPartKind.Battery):
				return "Increases power storage by 100.";
			case (Data.ShipPartKind.Booster):
				return "Consumes 60 power / second to generate directional thrust. Mouse wheel to rotate.";
			case (Data.ShipPartKind.Laser):
				return "Consumes 20 power to destroy a nearby asteroid. More lasers increases fire rate.";
			case (Data.ShipPartKind.Package):
				return "Needed for storing packages. Hit 'Space' once to charge the package cannon, then again to fire in the direction of the mouse. Be gentle!";
			case (Data.ShipPartKind.Shield):
				return "Consumes 15 power to prevent 10 damage per collision.";
			case (Data.ShipPartKind.SolarPanel):
				return "Increases power regeneration rate by 30 / second.";
			default:
		}
		return "";
	}
}






package ui;

import h2d.RenderContext;
import h2d.Text;
import h2d.Slider;
import h2d.Object;

typedef Field = {
	var name : String;
	var slider : h2d.Slider;
	var label : Text;
}

class DebugUI extends Object {
	var fields : Array<Field> = [];

	public function new(?p) {
		super(p);
	}

	public function addRange(name : String, initialValue = 1.0, onChange : Float -> Void, min = 0.0, max = 1.0) {
		var text = new Text(hxd.Res.fonts.marumonica.toFont(), this);
		text.text = name;
		var slider = new Slider(50, 10, text);
		slider.minValue = min;
		slider.maxValue = max;
		slider.onChange = () -> onChange(slider.value);
		slider.y = 15;
		slider.value = initialValue;
		fields.push({
			slider : slider,
			name : name,
			label : text,
		});
	}

	override function sync(ctx : RenderContext) {
		super.sync(ctx);
		for (i in 0...fields.length) {
			fields[i].label.y = i * 30;
		}
	}
}

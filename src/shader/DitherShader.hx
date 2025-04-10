package shader;

class DitherShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture : Sampler2D;
		@param var screenSize : Vec2;
		@global var ditherMatrix : Sampler2D;
		@global var time : Float;
		@param var mask : Sampler2D;
		@param var maskMatA : Vec3;
		@param var maskMatB : Vec3;
		@param var smoothAlpha : Bool;
		@param var bias : Float;
		@param var offset : Vec2;
		@:import h3d.shader.NoiseLib;
		function fragment() {
			noiseSeed = 3;
			var pixel : Vec4 = texture.get(calculatedUV);
			var texSize = screenSize / vec2(8);

			var vv = (fragCoord.xy + offset) / screenSize;

			var uv = vec3(input.uv, 1);
			var k = mask.get(vec2(uv.dot(maskMatA), uv.dot(maskMatB)));
			var alpha = k.a; // smoothAlpha ? k.a : float(k.a > 0);

			var threshold = ditherMatrix.get(vv * texSize); //
			var t1 = time * 0.1;
			var t2 = time * 0.3;
			var nsPos = fragCoord.xy / screenSize.xx * 2.0 + vec2(t1, t1 * 0.9);
			var ns = snoise(nsPos);
			var nsPos2 = fragCoord.xy / screenSize.yy * 8.0 - vec2(t2 * 0.2, t2);
			var ns2 = snoise(nsPos2);
			var lum = k.a; // dot(vec3(0.2126, 0.7152, 0.0722), k.rgb);
			var no = abs(ns * 0.5 + ns2 * 0.13) * 0.1;

			if( lum < 0.98 ) lum -= no;

			pixelColor = pixel;
			if( lum * 1.02 < threshold.r + bias ) {
				pixelColor.a = 0.0;
			}

			pixelColor.rgb *= k.rgb * pixelColor.a;
		}
	}
}

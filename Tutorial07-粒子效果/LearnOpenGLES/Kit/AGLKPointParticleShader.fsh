// UNIFORMS
uniform sampler2D       u_samplers2D;

// Varyings
varying lowp float      v_particleOpacity;


void main()
{
   lowp vec4 textureColor = texture2D(u_samplers2D,
      gl_PointCoord);
   textureColor.a = textureColor.a * v_particleOpacity;
   
   gl_FragColor = textureColor;
}

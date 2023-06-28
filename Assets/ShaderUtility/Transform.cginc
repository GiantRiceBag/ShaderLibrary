#define PI 3.1415926535

float2 Rotate(float2 uv,float rotation,bool clockwise = true)
{
	float sine,cosine;
	float angle = rotation * 2 * PI;
	sincos(angle,sine,cosine);

	return lerp(float2(cosine*uv.x + sine*uv.y,-sine*uv.x + cosine*uv.y),float2(cosine*uv.x - sine*uv.y,sine*uv.x + cosine*uv.y),clockwise);
}
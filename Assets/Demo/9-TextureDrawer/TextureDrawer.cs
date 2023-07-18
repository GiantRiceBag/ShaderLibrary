using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

public class TextureDrawer : MonoBehaviour
{
    public MeshRenderer meshRenderer;
    public RawImage rawImage;
    int pid_MainTexture = Shader.PropertyToID("_MainTex");

    [Range(0,30)] public int brushSize = 10;
    public Color curColor = Color.red;
    public Vector2 mousePosition = Vector2.zero;
    public Vector2 mouseDelta = Vector2.zero;
    RectTransform rect => rawImage.GetComponent<RectTransform>();
    int height => (int)rect.rect.height;
    int width => (int)rect.rect.width;
    public bool isPointerDown;
    public bool isPointerMoving;
    void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            isPointerDown = true;
            isPointerMoving = false;
            mouseDelta = Vector2.zero;
            mousePosition = Input.mousePosition;
            Draw();
        }
        if (Input.GetMouseButtonUp(0))
        {
            isPointerDown = false;
            isPointerMoving = false;
        }
    }

    private void LateUpdate()
    {
        if (isPointerDown)
        {
            mouseDelta = (Vector2)Input.mousePosition - mousePosition;
            mousePosition = Input.mousePosition;
            isPointerMoving = mouseDelta == Vector2.zero ? false : true;
        }
        if (isPointerMoving)
        {
            Draw();
        }
    }

    public bool GetUV(out Vector2 uv)
    {
        var rt = rawImage.transform.GetComponent<RectTransform>();
        Vector2 pointInRect;
        bool inside = true;

        // 屏幕空间坐标转Rect相对坐标(以物体锚点为中心)
        RectTransformUtility.ScreenPointToLocalPointInRectangle(
            rt,
            Input.mousePosition,
            null,
            out pointInRect);
       
        Vector2 textureCoord = pointInRect - rt.rect.min; // 锚点移动至左下角

        if (textureCoord.x < 0 || textureCoord.y < 0 || textureCoord.x >= width || textureCoord.y >= height)
            inside = false;

        // 坐标标准化
        textureCoord.x *= rawImage.uvRect.width / rt.rect.width;
        textureCoord.y *= rawImage.uvRect.height / rt.rect.height;
        textureCoord += rawImage.uvRect.min;

        uv = textureCoord;

        return inside;
    }

    void Draw()
    {
        Vector2 uv;
        if (GetUV(out uv))
        {
            // 两点间补全
            if(mouseDelta != Vector2.zero)
            {
                Vector2 origin = Vector2.Scale(uv, rect.rect.size) - mouseDelta;
                Vector2 dest = Vector2.Scale(uv, rect.rect.size);
                float distance = Vector2.Distance(origin, dest);

                Vector2 cur_origin;
                float step = 1 / distance;
                for(float lerp = 0;lerp <= 1;lerp += step)
                {
                    cur_origin = Vector2.Lerp(origin, dest, lerp);

                    var t = rawImage.texture as Texture2D;

                    int x = 0, y = brushSize;
                    DrawCircle(t, cur_origin, new Vector2(x, y), curColor);

                    while (x <= y)
                    {
                        x += 1;
                        float delta = Mathf.Pow(x, 2) + Mathf.Pow(y, 2) - Mathf.Pow(brushSize, 2);
                        if (delta > 0)
                            y -= 1;
                        DrawCircle(t, cur_origin, new Vector2(x, y), curColor);
                    }
                    Fill(t, cur_origin);
                    t.Apply();
                }
            }
            else
            {
                Vector2 origin = Vector2.Scale(uv, rect.rect.size);

                var t = rawImage.texture as Texture2D;

                int x = 0, y = brushSize;
                DrawCircle(t, origin, new Vector2(x, y), curColor);

                // Bresenham
                // 取第一象限 y>x 区域作为参考
                while (x <= y)
                {
                    x += 1;
                    // x^2 + y^2 -  r^2 = d
                    // 剔除 d > 0 的部分
                    float delta = Mathf.Pow(x, 2) + Mathf.Pow(y, 2) - Mathf.Pow(brushSize, 2);
                    if (delta > 0)
                        y -= 1;
                    DrawCircle(t, origin, new Vector2(x, y), curColor);
                }
                Fill(t, origin);
                t.Apply();
            }
        }
    }

    // 在圆内填充 有BUG 临时用用
    void Fill(Texture2D t,Vector2 coord)
    {
        if (coord.x < 0 || coord.x >= width || coord.y < 0 || coord.y >= height)
            return;
        
        if(t.GetPixel((int)coord.x,(int)coord.y) != curColor)
        {
            t.SetPixel((int)coord.x, (int)coord.y, curColor);
            Fill(t, coord + Vector2.up);
            Fill(t, coord + Vector2.down);
            Fill(t, coord + Vector2.right);
            Fill(t, coord + Vector2.left);
        }
    }

    // 八分法画圈
    void DrawCircle(Texture2D t,Vector2 origin,Vector2 xy,Color color)
    {
        DrawPixel(t,(int)xy.x + (int)origin.x, (int)xy.y + (int)origin.y, color);
        DrawPixel(t,(int)-xy.x + (int)origin.x, (int)xy.y + (int)origin.y, color);
        DrawPixel(t,(int)xy.x + (int)origin.x, (int)-xy.y + (int)origin.y, color);
        DrawPixel(t, (int)-xy.x + (int)origin.x, (int)-xy.y + (int)origin.y, color);
        DrawPixel(t, (int)xy.y + (int)origin.x, (int)xy.x + (int)origin.y, color);
        DrawPixel(t, (int)-xy.y + (int)origin.x, (int)xy.x + (int)origin.y, color);
        DrawPixel(t, (int)xy.y + (int)origin.x, (int)-xy.x + (int)origin.y, color);
        DrawPixel(t, (int)-xy.y + (int)origin.x, (int)-xy.x + (int)origin.y, color);
    }
    void DrawPixel(Texture2D t, int x,int y, Color color)
    {
        if (x < 0 || y < 0 || x >= width || y >= height)
            return;
        t.SetPixel(x, y, color);
    }

    private void Start()
    {
        ResetTexture();
    }

    void ResetTexture()
    {
        Texture2D texture = new Texture2D(width, height, TextureFormat.RGB24, false);
        Color32[] col = new Color32[width * height];
        for (int i = 0; i < col.Length; i++)
            col[i] = Color.white;
        texture.SetPixels32(col);
        texture.Apply();
        rawImage.texture = texture;
        meshRenderer.material.SetTexture(pid_MainTexture, texture);
    }

    private void OnGUI()
    {
        if (GUILayout.Button("Reset"))
            ResetTexture();
        if (GUILayout.Button("Red"))
            curColor = Color.red;
        if (GUILayout.Button("Green"))
            curColor = Color.green;
    }
}

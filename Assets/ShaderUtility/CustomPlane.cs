using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomPlane : MonoBehaviour
{
    public bool isStaticMesh;

    [Range(10, 256)] public int meshWidth = 10;
    [Range(10, 256)] public int meshHeight = 10;
    [Range(1, 256)] public int meshScale = 10;
    public Vector2 origin = new Vector2(0.5f, 0.5f);

    Mesh mesh;
    MeshFilter meshFilter;

    Vector3[] vertices;
    Vector2[] uvs;
    int[] triangles;

    private void Awake()
    {
        InitializeMesh();
        RegenerateMesh();
    }

    private void OnValidate()
    {
        InitializeMesh();
        RegenerateMesh();
    }

    private void FixedUpdate()
    {
        if (isStaticMesh)
            return;

        mesh.Clear();
        mesh.vertices = vertices;
        mesh.uv = uvs;
        mesh.triangles = triangles;
        mesh.RecalculateNormals();
    }

    void InitializeMesh()
    {
        vertices = new Vector3[meshWidth * meshHeight];
        uvs = new Vector2[meshWidth * meshHeight];
        triangles = new int[(meshWidth - 1) * (meshHeight - 1) * 6];

        meshFilter = GetComponent<MeshFilter>();
        mesh = new Mesh();
        meshFilter.sharedMesh = mesh;
    }

    // 重新生成网格
    void RegenerateMesh()
    {
        float deltaX = 1f / (float)meshWidth;
        float deltaY = 1f / (float)meshHeight;

        for (int y = 0; y < meshHeight; y++)
        {
            for (int x = 0; x < meshWidth; x++)
            {
                int index = y * meshWidth + x;
                vertices[index] = new Vector3(
                        meshScale * deltaX * (x - meshWidth * origin.x),
                        0,
                        meshScale * deltaY * (y - meshHeight * origin.y)
                    );
                uvs[index] = new Vector2((float)x / (float)(meshWidth-1), (float)y / (float)(meshHeight-1));
            }
        }

        int tindex = 0;
        for (int y = 0; y < meshHeight - 1; y++)
        {
            for (int x = 0; x < meshWidth - 1; x++)
            {
                // 三角网格索引 顺时针为正面 逆时针为背面
                // 左下三角网格
                triangles[tindex++] = y * meshWidth + x;
                triangles[tindex++] = y * meshWidth + x + meshWidth;
                triangles[tindex++] = y * meshWidth + x + meshWidth + 1;
                // 右上三角网格
                triangles[tindex++] = y  * meshWidth + x;
                triangles[tindex++] = y * meshWidth + x + 1 + meshWidth;
                triangles[tindex++] = y * meshWidth + x + 1;
            }
        }

        mesh.Clear();
        mesh.vertices = vertices;
        mesh.uv = uvs;
        mesh.triangles = triangles;
        mesh.RecalculateNormals();
    }
}

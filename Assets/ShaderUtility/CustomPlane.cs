using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomPlane : MonoBehaviour
{
    public bool isStaticMesh;

    [Range(2, 256)] public int meshSize = 8;
    [Range(1, 256)] public int meshScale = 10;

    Mesh mesh;
    MeshFilter meshFilter;

    Vector3 origin;
    Vector3[] vertices;
    Vector2[] uvs;
    int[] triangles;

    private void Awake()
    {
        InitializeMesh();
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

        origin = transform.position;
        mesh.Clear();
        mesh.vertices = vertices;
        mesh.uv = uvs;
        mesh.triangles = triangles;
        mesh.RecalculateNormals();
    }

    void InitializeMesh()
    {
        origin = transform.position;
        vertices = new Vector3[meshSize * meshSize];
        uvs = new Vector2[meshSize * meshSize];
        triangles = new int[(meshSize - 1) * (meshSize - 1) * 6];

        meshFilter = GetComponent<MeshFilter>();
        mesh = meshFilter.sharedMesh;
    }

    // 重新生成网格
    void RegenerateMesh()
    {
        float delta = 1f / (float)meshSize;

        for (int i = 0; i < meshSize; i++)
        {
            for (int j = 0; j < meshSize; j++)
            {
                int index = i * meshSize + j;
                vertices[index] = new Vector3(
                        meshScale * delta * (i - meshSize * 0.5f),
                        0,
                        meshScale * delta * (j - meshSize * 0.5f)
                    );
                uvs[index] = new Vector2((float)i / (float)meshSize, (float)j / (float)meshSize);
            }
        }

        int tindex = 0;
        for (int i = 0; i < meshSize - 1; i++)
        {
            for (int j = 0; j < meshSize - 1; j++)
            {
                // 三角网格索引 逆时针为正面 顺时针为背面
                // 左下三角网格
                triangles[tindex++] = i * meshSize + j;
                triangles[tindex++] = i * meshSize + j + meshSize + 1;
                triangles[tindex++] = i * meshSize + j + meshSize;
                // 右上三角网格
                triangles[tindex++] = i * meshSize + j;
                triangles[tindex++] = i * meshSize + j + 1;
                triangles[tindex++] = i * meshSize + j + 1 + meshSize;
            }
        }

        mesh.Clear();
        mesh.vertices = vertices;
        mesh.uv = uvs;
        mesh.triangles = triangles;
        mesh.RecalculateNormals();
    }
}

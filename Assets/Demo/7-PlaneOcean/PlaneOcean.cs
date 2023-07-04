using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Threading;
using System.Threading.Tasks;

[RequireComponent(typeof(MeshFilter))]
public class PlaneOcean : MonoBehaviour
{
    public bool isStaticMesh;

    [Range(2, 256)] public int meshSize = 8;
    [Range(1, 256)] public int meshScale = 10;
    [Space]
    [Range(0,1)]public float noiseStrength = 1;
    [Range(0, 2)] public float noiseScale = 1;
    public float noiseSpeed = 1;

    Mesh mesh;
    MeshFilter meshFilter;
    MeshCollider meshCollider;

    Vector3 origin;
    Vector3[] vertices;
    Vector2[] uvs;
    int[] triangles;

    bool isRunning = true;

    int sleepTimeMS;
    float time;

    private void Awake()
    {
        InitializeMesh();
    }

    private void Start()
    {
        Thread thread = new Thread(new ThreadStart(UpdateMesh));
        thread.Start();
    }

    private void OnDestroy()
    {
        isRunning = false;
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

        time = Time.time * noiseSpeed;
        sleepTimeMS = (int)(Time.fixedDeltaTime * 1000);
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
        meshCollider = GetComponent<MeshCollider>();
    }

    // 重新生成网格
    void RegenerateMesh()
    {
        float delta = 1f / (float)meshSize;

        for(int i = 0; i < meshSize; i++)
        {
            for(int j = 0; j < meshSize; j++)
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
        for(int i = 0; i < meshSize - 1; i++)
        {
            for(int j = 0;j<meshSize - 1; j++)
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

    void UpdateMesh()
    {
        while (isRunning)
        {
            float delta = 1f / (float)meshSize;

            for (int i = 0; i < meshSize; i++)
            {
                for (int j = 0; j < meshSize; j++)
                {
                    int index = i * meshSize + j;
                    float noise = Mathf.PerlinNoise((i * noiseScale + time), (j) * noiseScale + time) * noiseStrength;
                    vertices[index] = new Vector3(
                            meshScale * delta * (i - meshSize * 0.5f),
                            noise,
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
            Thread.Sleep(sleepTimeMS);
        }
    }
}

using System;
using System.Collections;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;

public class WaterGenerator : MonoBehaviour 
{
    public bool staticWater = false;

    [Range(2,256)]
    public int resolution = 16;

    public float size = 15f;

    [Range(1f,10f)]
    public float rippleNoiseReductionFactor = 5f;

    [Range(0.01f, 10f)]
    public float waveHeight = 1f;
    public float waveFrequency = 1f;
    [Range(1f, 10f)]
    public float waveSpeed = 1f;
    private float sineOffset = 0.1f;

    [Range(0.01f, 5f)]
    public float secondWaveHeight = 1f;
    public float secondWaveFrequency = 1f;
    [Range(1f, 10f)]
    public float secondWaveSpeed = 1f;
    private float secondSineOffset = 0.2f;

    private Vector3 position;
    private Mesh mesh;
    private Vector3[] vertices;
    private Vector2[] uvs;
    private int[] triangles;
    public Vector3[] Vertices
    {
        get => vertices;
        private set => vertices = value;
    }

    //Thread
    private bool isRun = true;
    private int sleepTimeMS;

    private void Awake()
    {
        initializeMesh();
        position = transform.position;
    }

    private void OnValidate()
    {
        initializeMesh();
        position = transform.position;
        CreateMesh();
    }

    void Start () 
    {
        Thread thread = new Thread(new ThreadStart(UpdateMesh));
        thread.Start();
    }

    void FixedUpdate()
    {
        if (!staticWater)
        {
            sleepTimeMS = (int)(Time.fixedDeltaTime * 1000);
            sineOffset += 0.01f * waveSpeed;
            secondSineOffset += 0.02f * secondWaveSpeed;

            if (mesh != null)
            {
                mesh.Clear();
                mesh.vertices = vertices;
                mesh.uv = uvs;
                mesh.triangles = triangles;
                mesh.RecalculateNormals();
            }
        }
        position = transform.position;
    }

    // Initializes the mesh
    void initializeMesh()
    {
        vertices = new Vector3[resolution * resolution];
        uvs = new Vector2[resolution * resolution];
        triangles = new int[(resolution - 1) * (resolution - 1) * 6];
        mesh = GetComponent<MeshFilter>().sharedMesh;
        if (mesh == null)
        {
            GetComponent<MeshFilter>().sharedMesh = new Mesh();
            mesh = GetComponent<MeshFilter>().sharedMesh;
        }
    }

    void CreateMesh() 
    {
        float s = size / (float)resolution;

        for (int x = 0; x < resolution; ++x)
        {
            for (int y = 0; y < resolution; ++y)
            {
                int i = x * resolution + y;
                vertices[i] = new Vector3(
                    s * (x - resolution * 0.5f),   // X
                    0, //Y
                    s * (y - resolution * 0.5f));  // Z
                uvs[i] = new Vector2((float)x / (resolution - 1), (float)y / (resolution - 1));
            }
        }

        int step = resolution;
        int index = 0;
        for (int y = 0; y < (resolution - 1); ++y)
        {
            for (int x = 0; x < (resolution - 1); ++x)
            {
                triangles[index++] = (x + y * resolution);
                triangles[index++] = (x + y * resolution) + step + 1;
                triangles[index++] = (x + y * resolution) + step;
                triangles[index++] = (x + y * resolution);
                triangles[index++] = (x + y * resolution) + 1;
                triangles[index++] = (x + y * resolution) + step + 1;
            }
        }

        if (mesh != null)
        {
            mesh.Clear();
            mesh.vertices = vertices;
            mesh.uv = uvs;
            mesh.triangles = triangles; 
            mesh.RecalculateNormals();
        }
    }

    void UpdateMesh()
    {
        while (isRun)
        {
            float s = size / (float)resolution;

            float offset = sineOffset;
            float soffset = secondSineOffset;
            for (int x = 0; x < resolution; ++x)
            {
                for (int y = 0; y < resolution; ++y)
                {
                    int i = x * resolution + y;
                    float noise = Mathf.PerlinNoise(x + offset, y + offset) / rippleNoiseReductionFactor;
                    vertices[i] = new Vector3(
                        s * (x - resolution * 0.5f),   // X
                        noise + //Y
                        waveHeight * Mathf.Sin(offset * waveFrequency) + 
                        secondWaveHeight * Mathf.Cos(soffset * secondWaveFrequency), 
                        s * (y - resolution * 0.5f));  // Z
                    uvs[i] = new Vector2((float)x / (resolution - 1), (float)y / (resolution - 1));
                }
                offset += 0.3f;
                soffset += 0.3f;
            }

            int step = resolution;
            int index = 0;
            for (int y = 0; y < (resolution - 1); ++y)
            {
                for (int x = 0; x < (resolution - 1); ++x)
                {
                    triangles[index++] = (x + y * resolution);
                    triangles[index++] = (x + y * resolution) + step + 1;
                    triangles[index++] = (x + y * resolution) + step;
                    triangles[index++] = (x + y * resolution);
                    triangles[index++] = (x + y * resolution) + 1;
                    triangles[index++] = (x + y * resolution) + step + 1;
                }
            }
            Thread.Sleep(sleepTimeMS);
        }
    }

    private void OnDestroy()
    {
        isRun = false;
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Dynamic2DWater : MonoBehaviour
{
    [Range(2, 256)] public int size = 16;
    [Range(1, 100)] public int width = 3;
    [Range(1, 100)] public int height = 3;
    [Space]
    [Min(0)]public float spread = 1;
    [Min(0)] public float t = 30;
    [Min(0)] public float damping = 5;
    [Min(0)] public float velocityFactor = 3;

    Mesh mesh;
    MeshFilter meshFilter;

    Vector3[] vertices;
    Vector2[] uvs;
    int[] triangles;
    [Space]
    public float[] verticesVel;
    public float[] verticesAcc;
    public float[] leftDeltas;
    public float[] rightDeltas;

    public GameObject box;
    public GameObject sphere;

    float originHeight => transform.position.y;

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

    private void Update()
    {
        InstantiateObj();
        SpringMovement();
    }

    public void SpringMovement()
    {
        // 记录高度差
        for(int i = 0; i < size; i++)
        {
            if(i > 0)
            {
                leftDeltas[i] = spread * ((vertices[i].y - vertices[i - 1].y));  // 当前点和左侧点的高度差
                verticesVel[i - 1] += leftDeltas[i]; // 左侧点施力
            }
            if (i < size - 1)
            {
                rightDeltas[i] = spread * (vertices[i].y - vertices[i + 1].y); // 当前点和右侧点点的高度差
                verticesVel[i + 1] += rightDeltas[i]; // 右侧点施力
            }
        }

        // 弹簧运动计算
        for (int i = 0; i < size; i++)
        {
            verticesAcc[i] = - t *(vertices[i].y - (height * 0.5f )) - verticesVel[i] * damping; // 相对高度
            verticesVel[i] += verticesAcc[i] * Time.deltaTime;
            vertices[i] = vertices[i] + Vector3.up * verticesVel[i] * Time.deltaTime;

            mesh.SetVertices(vertices);
        }
    }

    public void Splash(Collider2D col,float force)
    {
        float radius = col.bounds.max.x - col.bounds.min.x; // 碰撞物体半径
        Vector2 center = new Vector2(col.bounds.center.x,transform.position.y + height * 0.5f); // 碰撞物体到表面的垂直点
   
        for (int i = 0; i < size; i++)
        {
            float normalDistance = Vector2.Distance(transform.position + vertices[i], center) / radius;
           if (normalDistance <= 1)  // 选择在半径内的点
            {
                // 修改碰撞顶点高度
                vertices[i] += force * Vector3.up * (1 - normalDistance * normalDistance);
            }
        }
        mesh.SetVertices(vertices);
    }

    void InstantiateObj()
    {
        if (Input.GetMouseButtonDown(0))
        {
            GameObject obj = Instantiate(box);
            obj.transform.position = Vector3.Scale(Camera.main.ScreenToWorldPoint(Input.mousePosition),new Vector3(1,1,0));
        }
        if (Input.GetMouseButtonDown(1))
        {
            GameObject obj = Instantiate(sphere);
            obj.transform.position = Vector3.Scale(Camera.main.ScreenToWorldPoint(Input.mousePosition), new Vector3(1, 1, 0));
        }
    }

    private void OnTriggerEnter2D(Collider2D collision)
    {
        Splash(collision, collision.GetComponent<Rigidbody2D>().velocity.y * velocityFactor);
    }

    private void OnDrawGizmos()
    {
        for(int i = 0; i < size; i++)
        {
            Gizmos.color = Color.blue;
            Gizmos.DrawSphere(transform.position + vertices[i], 0.1f);
        }
    }

    void InitializeMesh()
    {
        meshFilter = GetComponent<MeshFilter>();
        mesh = meshFilter.sharedMesh;

        vertices = new Vector3[size * 2];
        uvs = new Vector2[size * 2];
        triangles = new int[(size - 1) * 6];

        leftDeltas = new float[size];
        rightDeltas = new float[size];
        verticesAcc = new float[size];
        verticesVel = new float[size];
    }

    void RegenerateMesh()
    {
        float delta = 1f / (float)size * width;
        int index;
        for(int i = 0; i < size; i++)
        {
            // 顶点下标 从左往右 从上至下
            // 上排
            vertices[i] = new Vector3(
                    i * delta - 0.5f * width,
                    0.5f * height,
                    0
                );
            // 下排
            vertices[size + i] = new Vector3(
                    i * delta - 0.5f * width,
                    -0.5f * height,
                    0
                );
            uvs[i] = new Vector2(i / (float)size, 1);
            uvs[size + i] = new Vector2( i / (float)size, 0);
        }

        index = 0;
        // 顺时针为一个正面三角片
        for(int i = 0; i < size - 1;i++)
        {
            triangles[index++] = i;
            triangles[index++] = i + 1;
            triangles[index++] = i + size;
            triangles[index++] = i + size;
            triangles[index++] = i + 1;
            triangles[index++] = i + size + 1;
        }

        mesh.Clear();
        mesh.vertices = vertices;
        mesh.uv = uvs;
        mesh.triangles = triangles;
        mesh.RecalculateNormals();
    }
}

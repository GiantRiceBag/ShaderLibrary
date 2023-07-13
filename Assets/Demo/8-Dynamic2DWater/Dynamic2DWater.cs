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
        // ��¼�߶Ȳ�
        for(int i = 0; i < size; i++)
        {
            if(i > 0)
            {
                leftDeltas[i] = spread * ((vertices[i].y - vertices[i - 1].y));  // ��ǰ�������ĸ߶Ȳ�
                verticesVel[i - 1] += leftDeltas[i]; // ����ʩ��
            }
            if (i < size - 1)
            {
                rightDeltas[i] = spread * (vertices[i].y - vertices[i + 1].y); // ��ǰ����Ҳ���ĸ߶Ȳ�
                verticesVel[i + 1] += rightDeltas[i]; // �Ҳ��ʩ��
            }
        }

        // �����˶�����
        for (int i = 0; i < size; i++)
        {
            verticesAcc[i] = - t *(vertices[i].y - (height * 0.5f )) - verticesVel[i] * damping; // ��Ը߶�
            verticesVel[i] += verticesAcc[i] * Time.deltaTime;
            vertices[i] = vertices[i] + Vector3.up * verticesVel[i] * Time.deltaTime;

            mesh.SetVertices(vertices);
        }
    }

    public void Splash(Collider2D col,float force)
    {
        float radius = col.bounds.max.x - col.bounds.min.x; // ��ײ����뾶
        Vector2 center = new Vector2(col.bounds.center.x,transform.position.y + height * 0.5f); // ��ײ���嵽����Ĵ�ֱ��
   
        for (int i = 0; i < size; i++)
        {
            float normalDistance = Vector2.Distance(transform.position + vertices[i], center) / radius;
           if (normalDistance <= 1)  // ѡ���ڰ뾶�ڵĵ�
            {
                // �޸���ײ����߶�
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
            // �����±� �������� ��������
            // ����
            vertices[i] = new Vector3(
                    i * delta - 0.5f * width,
                    0.5f * height,
                    0
                );
            // ����
            vertices[size + i] = new Vector3(
                    i * delta - 0.5f * width,
                    -0.5f * height,
                    0
                );
            uvs[i] = new Vector2(i / (float)size, 1);
            uvs[size + i] = new Vector2( i / (float)size, 0);
        }

        index = 0;
        // ˳ʱ��Ϊһ����������Ƭ
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

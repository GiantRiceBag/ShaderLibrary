using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bresenhem : MonoBehaviour
{
    public Vector3 origin;
    public Vector3 dest;

    private void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            RaycastHit hit;
            
            if (Physics.Raycast(ray, out hit))
            {
                Vector3 pos = hit.point;
                pos.x = Mathf.Floor(pos.x);
                pos.z = Mathf.Floor(pos.z);
                origin = pos;
            }
        }
        if (Input.GetMouseButtonDown(1))
        {
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            RaycastHit hit;
            if (Physics.Raycast(ray, out hit))
            {
                Vector3 pos = hit.point;
                pos.x = Mathf.Floor(pos.x);
                pos.z = Mathf.Floor(pos.z);
                dest = pos;
            }
        }
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.white;
        for (int i = 0; i <= 10; i++)
        {
            Gizmos.DrawLine(Vector3.forward * i + 0.001f * Vector3.up, Vector3.forward * i + 10 * Vector3.right + 0.001f * Vector3.up);
        }
        for (int i = 0; i <= 10; i++)
        {
            Gizmos.DrawLine(Vector3.right * i + 0.001f * Vector3.up, Vector3.right * i + 10 * Vector3.forward + 0.001f * Vector3.up);
        }

        Gizmos.color = Color.yellow;
        Gizmos.DrawSphere(origin, 0.2f);
        Gizmos.color = Color.red;
        Gizmos.DrawSphere(dest, 0.2f);

        if(origin != dest)
        {
            #region bresenhem
            Gizmos.color = Color.cyan;
            Vector2 offset = Vector2.one * 0.5f;

            float a = (dest.z - origin.z) / (dest.x - origin.x);
            float b = dest.z - a * dest.x;

            int x = (int)origin.x;
            int z = (int)origin.z;
            float dx = dest.x - origin.x;
            float dz = dest.z - origin.z;
            float delta = 2 * dz - dx;

            while (x < dest.x)
            {
                if (delta <= 0)
                {
                    delta += 2 * dz;
                }
                else
                {
                    delta += 2 * dz - 2 * dx;
                    z++;
                }
                Gizmos.DrawCube(new Vector3(x + offset.x, 0, z + offset.y), Vector3.one);
                x++;
            }
            #endregion

            #region another
            Gizmos.color = Color.red;
            Gizmos.DrawLine(origin, dest);

            Gizmos.color = Color.white;

            x = (int)origin.x;
            z = (int)origin.z;

            a = (dest.z - origin.z) / (dest.x - origin.x);
            b = dest.z - a * dest.x;
            System.Func<float, float> func = (xx) => a * xx + b;
            while (x < dest.x)
            {
                z = Mathf.FloorToInt(func(x));
                Gizmos.DrawCube(new Vector3(x + offset.x, 0, z + offset.y), Vector3.one* 0.8f);
                x++;
            }
            #endregion

        }
    }
}

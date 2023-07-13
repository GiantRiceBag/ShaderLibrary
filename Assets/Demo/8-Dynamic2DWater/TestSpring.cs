using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestSpring : MonoBehaviour
{
    Vector3 origin;
    // ma = -kx
    // a = -kx / m
    // k/m = t
    // a = -xt
    public float t = 100;
    public Vector3 vel;
    public Vector3 acc;
    public float dampening = 2;

    private void Awake()
    {
        origin = transform.position;
    }

    private void Update()
    {
        acc = - (t * (transform.position - origin)) - vel * dampening;

        transform.position += vel * Time.deltaTime;
        vel += acc * Time.deltaTime;
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.yellow;
        Gizmos.DrawSphere(origin, 0.3f);
    }
}

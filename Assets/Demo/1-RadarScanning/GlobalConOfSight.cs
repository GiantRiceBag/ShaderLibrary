using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class GlobalConOfSight : MonoBehaviour
{
    [Header("Setting")]
    [SerializeField] float scanningRadius = 20;
    [SerializeField] float rotationSpeed = 10;
    [Header("References")]
    [SerializeField] Camera depthCam;
    [SerializeField] MeshRenderer meshRenderer;
    Material material => meshRenderer.sharedMaterial;

    readonly int pid_MainTex = Shader.PropertyToID("_MainTex");
    readonly int pid_MatrixVP = Shader.PropertyToID("_MatrixVP");

    private void Start()
    {
        RenderTexture depthTex = new RenderTexture(depthCam.pixelWidth, depthCam.pixelHeight, 24, RenderTextureFormat.Depth);
        depthCam.targetTexture = depthTex;
        material.SetTexture(pid_MainTex, depthTex);
    }

    private void Update()
    {
        depthCam.farClipPlane = Mathf.Abs(scanningRadius);
        meshRenderer.transform.localScale = Vector3.one * Mathf.Abs(scanningRadius);

        material.SetMatrix(pid_MatrixVP, depthCam.projectionMatrix * depthCam.worldToCameraMatrix);

        transform.Rotate(Vector3.up, Time.deltaTime * rotationSpeed);
    }
}

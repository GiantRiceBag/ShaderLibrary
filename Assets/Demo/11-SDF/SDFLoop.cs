using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SDFLoop : MonoBehaviour
{
    public float speed = 1;

    private float lerpValue = 0;
    private readonly int shaderLerpValue = Shader.PropertyToID("_Lerp");

    private IEnumerator Start()
    {
        Material mat = new Material(GetComponent<MeshRenderer>().sharedMaterial);
        GetComponent<MeshRenderer>().material = mat;

        mat.SetFloat(shaderLerpValue, lerpValue);

        while(true)
        {
            while(lerpValue < 1)
            {
                lerpValue = Mathf.Clamp(lerpValue+ Time.deltaTime * speed,0,1);
                mat.SetFloat(shaderLerpValue, lerpValue);
                yield return null;
            }
            yield return new WaitForSeconds(1);
            while (lerpValue > 0)
            {
                lerpValue = Mathf.Clamp(lerpValue - Time.deltaTime * speed, 0, 1);
                mat.SetFloat(shaderLerpValue, lerpValue);
                yield return null;
            }
            yield return new WaitForSeconds(1);
        }
    }
}

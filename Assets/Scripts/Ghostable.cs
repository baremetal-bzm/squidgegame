using System.Linq;
using UnityEngine;

public class Ghostable : MonoBehaviour
{
    
    public GameObject CreateGhostClone(Material material, float dotDensity)
    {
        GameObject ghost = new GameObject(name + " (Ghost)");
        ghost.transform.SetPositionAndRotation(transform.position, transform.rotation);

        var mpb = new MaterialPropertyBlock();
        mpb.SetFloat("_DotDensity", dotDensity);

        var activeSkinned = GetComponentsInChildren<SkinnedMeshRenderer>().Where(r => r.enabled).ToArray();

        if (activeSkinned.Length > 0)
        
            {
            ghost.transform.localScale = Vector3.one; // BakeMesh already bakes world scale into vertices

            foreach (var skinned in activeSkinned)
            {
                GameObject part = new GameObject(skinned.name + " (Ghost Part)");
                part.transform.SetParent(ghost.transform, worldPositionStays: false);
                part.transform.SetPositionAndRotation(skinned.transform.position, skinned.transform.rotation);
                part.transform.localScale = Vector3.one;

                Mesh baked = new Mesh();
                skinned.BakeMesh(baked);

                part.AddComponent<MeshFilter>().sharedMesh = baked;
                var partRenderer = part.AddComponent<MeshRenderer>();
                partRenderer.sharedMaterial = material;
                partRenderer.renderingLayerMask = skinned.renderingLayerMask; // match the source renderer's layer
                partRenderer.SetPropertyBlock(mpb); //set dot density higher for ghosts
            }
        }
        
        else
        {
            // Not baked — this is the raw shared mesh, so ya need to set scale 
            ghost.transform.localScale = transform.lossyScale;
            var meshFilter = GetComponentInChildren<MeshFilter>();
            var sourceMeshRenderer = GetComponentInChildren<MeshRenderer>();
            if (meshFilter != null && sourceMeshRenderer != null)
            {
                ghost.AddComponent<MeshFilter>().sharedMesh = meshFilter.sharedMesh;
                var ghostRenderer = ghost.AddComponent<MeshRenderer>();
                ghostRenderer.sharedMaterial = material;
                ghostRenderer.renderingLayerMask = sourceMeshRenderer.renderingLayerMask;
                ghostRenderer.SetPropertyBlock(mpb);
            }
            else
            {
                Debug.LogWarning($"Ghostable on {name}: no MeshFilter or active SkinnedMeshRenderer found in children.", this);
            }
        }

        return ghost;
    }
}

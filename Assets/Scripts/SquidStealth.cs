//script to make squids transparent when at a distance so they dont appear as black splotches moving across beacon-lit areas
using System.Linq;
using UnityEngine;

public class SquidStealth : MonoBehaviour
{
    [Header("Stealth Fade")]
    public float visibleDistance = 5f;
    public float fadeDistance = 10f;

    private Transform player;
    private MaterialPropertyBlock mpb;

    void Awake()
    {
        var playerSwim = FindAnyObjectByType<PlayerSwim>();
        if (playerSwim != null) player = playerSwim.transform;

        mpb = new MaterialPropertyBlock();
    }

    void Update()
    {
        if (player == null) return;

        float distance = Vector3.Distance(transform.position, player.position);
        float alpha = 1f - Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(visibleDistance, fadeDistance, distance));
        //alpha = distance < 10f ? 1f : 0f;

        var activeRenderers = GetComponentsInChildren<SkinnedMeshRenderer>().Where(r => r.enabled);
        foreach (var r in activeRenderers)
        {
            r.GetPropertyBlock(mpb);
            mpb.SetFloat("_StealthAlpha", alpha);
            r.SetPropertyBlock(mpb);
        }
    }
}
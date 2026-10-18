using UnityEngine;

public class GhostFader : MonoBehaviour
{
    private BeaconController beacon;
    private float holdDuration, fadeDuration, revealedAt;
    private bool revealed;
    private Renderer[] renderers;
    private MaterialPropertyBlock mpb;

    public void Initialize(BeaconController beacon, float hold, float fade)
    {
        this.beacon = beacon;
        holdDuration = hold;
        fadeDuration = fade;
        renderers = GetComponentsInChildren<Renderer>();
        //mpb = new MaterialPropertyBlock();
    }

    void Update()
    {
        if (!revealed)
        {
            float dist = Vector3.Distance(transform.position, beacon.transform.position);
            if (dist <= beacon.CurrentPulseRadius)
            {
                revealed = true;
                revealedAt = Time.time;
            }
            return;
        }

        float fadeElapsed = (Time.time - revealedAt) - holdDuration;
        if (fadeElapsed <= 0f) return; // still fully visible

        float fade = 1f - Mathf.Clamp01(fadeElapsed / fadeDuration);
        foreach (var r in renderers)
        {
            var mpb = new MaterialPropertyBlock();
            r.GetPropertyBlock(mpb);
            mpb.SetFloat("_GhostFade", fade);
            r.SetPropertyBlock(mpb);
        }

        if (fade <= 0f) Destroy(gameObject);
    }
}
using System.Collections.Generic;
using UnityEngine;

public class BeaconController : MonoBehaviour
{
    [Header("Pulse")]
    public float pulseSpeed = 0.05f;          // world units/sec the reveal wave travels
    [Header("Ghosts")]
    public float ghostHoldDuration = 15f;    // seconds fully visible once revealed
    public float ghostFadeDuration = 1.5f;  // seconds to fade to black after the hold
    public Material ghostMaterial;
    public float ghostDotDensity = 20f;   // higher = denser dots, ghost-only
    private Light beaconLight;
    private float spawnTime;
    private float range;
    private List<GameObject> activeGhosts = new List<GameObject>();

    public float CurrentPulseRadius => Mathf.Min(pulseSpeed * (Time.time - spawnTime), range);

    void Awake()
    {
        beaconLight = GetComponent<Light>();
        range = beaconLight.range;
        spawnTime = Time.time;
        Activate(transform.position);
    }

    void Update()
    {
        UpdateShaderGlobals();
    }
    // Moves the beacon, restarts the pulse, and takes a fresh set of ghost snapshots —
    // call this on button press as well as once automatically at scene start.
    public void Activate(Vector3 worldPosition)
    {
        transform.position = worldPosition;
        spawnTime = Time.time;

        foreach (var ghost in activeGhosts)
        {
            if (ghost != null) Destroy(ghost);
        }
        activeGhosts.Clear();

        SpawnGhosts();
        UpdateShaderGlobals();
    }

    void SpawnGhosts()
    {
        if (ghostMaterial == null)
        {
            Debug.LogError("BeaconController: Ghost Material is not assigned — ghosts will spawn without a material.", this);
            return;
        }
        foreach (var g in FindObjectsByType<Ghostable>())
        {
            if (Vector3.Distance(g.transform.position, this.transform.position) < range) { //only spawn ghosts if theyre within range
            GameObject clone = g.CreateGhostClone(ghostMaterial, ghostDotDensity);
            clone.AddComponent<GhostFader>().Initialize(this, ghostHoldDuration, ghostFadeDuration);
            activeGhosts.Add(clone);
            }
        }
    }
    void UpdateShaderGlobals()
    {
        Shader.SetGlobalVector("_BeaconPositionWS", transform.position);
        Shader.SetGlobalFloat("_BeaconRange", range);
        Shader.SetGlobalFloat("_BeaconPulseRadius", CurrentPulseRadius);
    }
}

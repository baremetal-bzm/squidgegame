using UnityEngine;

//not needed if not using the screenspace bubble effect
// attach to the camera associated w/ underwater Full Screen Pass
// computes where world +Y currently projects on screenspace, sets relevant transforms in UnderwaterScreenEffect.shader

[RequireComponent(typeof(Camera))]
public class UnderwaterEffectController : MonoBehaviour
{
    [Tooltip("Material assigned to the Full Screen Pass Renderer Feature (uses UnderwaterScreenEffect).")]
    public Material underwaterMaterial;

    [Tooltip("Multiplies real time; set to 0 to pause the bubbles, or scale for slow-mo/fast-forward.")]
    public float timeScale = 1f;

    static readonly int BubbleUpDirId = Shader.PropertyToID("_BubbleUpDir");
    static readonly int EffectTimeId = Shader.PropertyToID("_EffectTime");

    float _effectTime;

    //initialize this to straight up to guard against screenDir below possibly being 0
    Vector2 _lastScreenDir = Vector2.up;

    void Update()
    {
        if (underwaterMaterial == null) return;

        _effectTime += Time.deltaTime * timeScale;

        Vector3 worldUp = Vector3.up;
        Vector3 camRight = transform.right;
        Vector3 camUp = transform.up;

        // Project world +Y onto the camera's screen-aligned axes.
        float x = Vector3.Dot(worldUp, camRight);
        float y = Vector3.Dot(worldUp, camUp);
        Vector2 screenDir = new Vector2(x, y);

        if (screenDir.sqrMagnitude > 0.0001f)
        {
            _lastScreenDir = screenDir.normalized;
        }

        underwaterMaterial.SetVector(BubbleUpDirId, _lastScreenDir);
        underwaterMaterial.SetFloat(EffectTimeId, _effectTime);
    }
}

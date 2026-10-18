using UnityEngine;

// Attach to the "UnderwaterBubbles" Particle System GameObject.
[RequireComponent(typeof(ParticleSystem))]
public class UnderwaterBubbleEmitter : MonoBehaviour
{
    [Tooltip("Usually the player or main camera. Only its position is used.")]
    public Transform followTarget;

    void OnEnable()
    {
        GetComponent<ParticleSystem>().Play();
    }

    void LateUpdate()
    {
        if (followTarget != null)
        {
            transform.position = followTarget.position;
        }
    }
}


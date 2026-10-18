using UnityEngine;

public class SwimChaseCamera : MonoBehaviour
{
    public Transform target;
    public Vector3 offset = new(0f, 1.5f, -5f); // relative to the whale's own facing
    public float followSharpness = 5f;

    void LateUpdate()
    {
        if (target == null) return;

        Vector3 desiredPosition = target.TransformPoint(offset);
        transform.position = Vector3.Lerp(transform.position, desiredPosition, followSharpness * Time.deltaTime);
        transform.rotation = Quaternion.Slerp(transform.rotation, target.rotation, followSharpness * Time.deltaTime);
    }
}
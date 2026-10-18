using Unity.VisualScripting;
using UnityEngine;

public class NPCWander : MonoBehaviour
{
    [Header("Wander Volume")]
    public float wanderRadius = 10f;   // how far from spawn it'll roam
    public bool wanderIn3D = true;     // false = flatten to horizontal plane only

    [Header("Movement")]
    public float moveSpeed = 2f;
    public float turnSpeed = 2f;
    public float arrivalTolerance = 0.5f;
    public float minPauseTime = 0.5f;
    public float maxPauseTime = 2f;

    private Vector3 spawnPoint;
    private Vector3 targetPoint;
    private float pauseTimer;
    private bool paused;
    private CapsuleCollider collider;

    private bool isActive;

    void Start()
    {
        collider = GetComponent<CapsuleCollider>();
        spawnPoint = transform.position;
        PickNewTarget();
    }

    public void SetActive(bool active)
    {
        isActive = active;
    }

    void Update()
    {
        if (!isActive) return;

        if (paused)
        {
            pauseTimer -= Time.deltaTime;
            if (pauseTimer <= 0f)
            {
                paused = false;
                PickNewTarget();
            }
            return;
        }

        Vector3 toTarget = targetPoint - transform.position;

        if (toTarget.magnitude <= arrivalTolerance)
        {
            paused = true;
            pauseTimer = Random.Range(minPauseTime, maxPauseTime);
            return;
        }

        Quaternion targetRotation = Quaternion.LookRotation(toTarget.normalized);
        transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, turnSpeed * Time.deltaTime);
        transform.position += transform.forward * moveSpeed * Time.deltaTime;
    }

    void PickNewTarget()
    {
        Vector3 offset = wanderIn3D
            ? Random.insideUnitSphere * wanderRadius
            : (Vector3)(Random.insideUnitCircle * wanderRadius); // implicit: Vector2 -> Vector3 puts it in XY, so swap to XZ below

        if (!wanderIn3D) {
            //offset = new Vector3(offset.x, 0f, offset.y);
            offset.z = offset.y;
            offset.y = 0f;
                }

        targetPoint = spawnPoint + offset;
        Vector3 currentPoint = transform.position;
        Vector3 path = targetPoint - currentPoint;
        Vector3 dir = Vector3.Normalize(path);
        float dist = path.magnitude; 
        if(CheckCapsuleCollision(dir, dist)) //if would cause collision, set paused and wait to try again
        {
            paused = true;
            pauseTimer = Random.Range(minPauseTime, maxPauseTime);
        }
    }
    void GetCapsulePoints(out Vector3 point1, out Vector3 point2, out float radius)
    {
        // 1. Get the lossy scale to handle uniform scaling
        Vector3 lossyScale = collider.transform.lossyScale;

        // 2. Determine radius and height based on the direction axis
        // 0 = X-Axis, 1 = Y-Axis, 2 = Z-Axis
        int direction = collider.direction;

        float scaleX = Mathf.Abs(lossyScale.x);
        float scaleY = Mathf.Abs(lossyScale.y);
        float scaleZ = Mathf.Abs(lossyScale.z);

        float maxRadiusScale = 0f;
        float heightScale = 0f;
        Vector3 localCapsuleDir = Vector3.up;

        switch (direction)
        {
            case 0: // X-Axis
                maxRadiusScale = Mathf.Max(scaleY, scaleZ);
                heightScale = scaleX;
                localCapsuleDir = Vector3.right;
                break;
            case 1: // Y-Axis
                maxRadiusScale = Mathf.Max(scaleX, scaleZ);
                heightScale = scaleY;
                localCapsuleDir = Vector3.up;
                break;
            case 2: // Z-Axis
                maxRadiusScale = Mathf.Max(scaleX, scaleY);
                heightScale = scaleZ;
                localCapsuleDir = Vector3.forward;
                break;
        }

        // 3. Calculate final world radius
        radius = collider.radius * maxRadiusScale;

        // 4. Calculate half-height between the center of the cap spheres
        float scaledHeight = collider.height * heightScale;
        float halfHeight = (scaledHeight / 2f) - radius;
        if (halfHeight < 0f) halfHeight = 0f; // Clamp if capsule height is smaller than diameter

        // 5. Transform local points to world space
        Vector3 localCenter = collider.center;
        Vector3 worldCenter = collider.transform.TransformPoint(localCenter);
        Vector3 worldDirection = collider.transform.TransformDirection(localCapsuleDir);

        point1 = worldCenter + worldDirection * halfHeight;
        point2 = worldCenter - worldDirection * halfHeight;
    }
    bool CheckCapsuleCollision(Vector3 direction, float distance)
    {
        if(direction == Vector3.zero) return false; //in the off chance that you picked same point randomly, no movement = no collision
        GetCapsulePoints(out Vector3 point1, out Vector3 point2, out float radius);
        return Physics.CapsuleCast(point1, point2, radius, direction, distance);
    }
}
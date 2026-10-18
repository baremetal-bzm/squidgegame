using UnityEditor.Toolbars;
using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(CharacterController))]
public class PlayerSwim : MonoBehaviour
{
    [Header("Movement")]
    public float moveSpeed = 5f;
    public float boostMultiplier = 2f;

    [Header("Look")]
    public float lookSensitivity = 2f;
    public float rollSpeed = 90f; // degrees/sec
    [SerializeField] private float initialPitch = 30f;

    [Header("Bounds")]
    [SerializeField] private float boundsMargin = 2f; // keep player slightly inside the edge
    [SerializeField] private float waterSurfaceY = 100f;
    //[SerializeField] private float minDepthBelowSurface = 1f;
    //[SerializeField] private float minHeightAboveFloor = 2f;

    private CharacterController controller;
    private Animator anim;
    private bool firstMouse = true;
    private float pitchLimit = 90f;

    private float minX, maxX, minZ, maxZ, yaw, pitch, roll;

    void Awake()
    {
        controller = GetComponent<CharacterController>();
        anim = GetComponentInChildren<Animator>(); 
        Cursor.lockState = CursorLockMode.Locked; // mouse drives look, not a cursor on screen, might be unnecessary given gameflowmanager calls this too

        CalculateTerrainBounds();
        SetSpawnToCenter();

        Vector3 startAngles = transform.eulerAngles;
        pitch = startAngles.x;
        yaw = startAngles.y;
        roll = startAngles.z;
    }

    void Update()
    {
        HandleLook();
        HandleMovement();
        ClampToBounds();
        //update anim for fast swimming
        anim.SetBool("SwiftSwim", Keyboard.current.leftShiftKey.isPressed);
        
    }

    void HandleLook()
    {
        if (firstMouse) //guard against first frame overshooting you and flipping you too much
        {
            firstMouse = false;
            return;
        }

        Vector2 mouseDelta = lookSensitivity * Time.deltaTime * Mouse.current.delta.ReadValue();

        yaw += mouseDelta.x;
        pitch -= mouseDelta.y;
        pitch = Mathf.Clamp(pitch, -pitchLimit, pitchLimit); //clamp to prevent inverting pitch

        //float rollInput = 0f; //can maybe comment out this stuff roll doesnt seem that necessary
        //if (Keyboard.current.qKey.isPressed) rollInput += 1f;
        //if (Keyboard.current.eKey.isPressed) rollInput -= 1f;
        //roll += rollInput *rollSpeed * Time.deltaTime;

        transform.rotation = Quaternion.AngleAxis(yaw, Vector3.up)
                        * Quaternion.AngleAxis(pitch, Vector3.right)
                        * Quaternion.AngleAxis(roll, Vector3.forward);

        //do this version if you wanna let players do a barrel roll
        //float flipx = transform.up.y >= 0f ? 1f : -1f;
        //transform.Rotate(Vector3.up, flipx* mouseDelta.x, Space.World);//Space.Self);
        //transform.Rotate(Vector3.right, -mouseDelta.y, Space.Self);
        //float roll = 0f;
        //if (Keyboard.current.qKey.isPressed) roll += 1f;
        //if (Keyboard.current.eKey.isPressed) roll -= 1f;
        //transform.Rotate(Vector3.forward, roll * rollSpeed * Time.deltaTime, Space.Self);
    }

    void HandleMovement()
    {
        var kb = Keyboard.current;
        Vector3 move = Vector3.zero;

        if (kb.wKey.isPressed) move += Vector3.forward;
        if (kb.sKey.isPressed) move += Vector3.back;
        if (kb.aKey.isPressed) move += Vector3.left;
        if (kb.dKey.isPressed) move += Vector3.right;
        if (kb.spaceKey.isPressed) move += Vector3.up;
        if (kb.leftCtrlKey.isPressed) move += Vector3.down;

        move = transform.TransformDirection(move.normalized);
        float speed = moveSpeed * (kb.leftShiftKey.isPressed ? boostMultiplier : 1f);
        controller.Move(move * speed * Time.deltaTime);
    }
    private void CalculateTerrainBounds()
    {
        Terrain terrain = Terrain.activeTerrain;
        Vector3 terrainPos = terrain.transform.position;
        Vector3 terrainSize = terrain.terrainData.size;

        minX = terrainPos.x + boundsMargin;
        maxX = terrainPos.x + terrainSize.x - boundsMargin;
        minZ = terrainPos.z + boundsMargin;
        maxZ = terrainPos.z + terrainSize.z - boundsMargin;
    }

    private void SetSpawnToCenter()
    {
        Terrain terrain = Terrain.activeTerrain;
        Vector3 terrainPos = terrain.transform.position;
        Vector3 terrainSize = terrain.terrainData.size;

        float centerX = terrainPos.x + terrainSize.x / 2f;
        float centerZ = terrainPos.z + terrainSize.z / 2f;

        float floorY = terrain.SampleHeight(new Vector3(centerX, 0f, centerZ)) + terrainPos.y;
        //float spawnY = Mathf.Lerp(floorY + minHeightAboveFloor, waterSurfaceY, 0.5f);
        float spawnY = 50f;

        // disable character controller since apparently that can cause issues with teleporting
        controller.enabled = false;
        transform.position = new Vector3(centerX, spawnY, centerZ);
        yaw = 0f;
        pitch = initialPitch;
        roll = 0f;
        transform.rotation = Quaternion.AngleAxis(yaw, Vector3.up)
                * Quaternion.AngleAxis(pitch, Vector3.right)
                * Quaternion.AngleAxis(roll, Vector3.forward);
        controller.enabled = true;
    }

    private void ClampToBounds()
    {
        Vector3 pos = transform.position;
        pos.x = Mathf.Clamp(pos.x, minX, maxX);
        pos.y = Mathf.Clamp(pos.y, -100, waterSurfaceY);
        pos.z = Mathf.Clamp(pos.z, minZ, maxZ);
        transform.position = pos;
    }
}

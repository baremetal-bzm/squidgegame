using System.Collections.Generic;
using UnityEngine;

//tracks whether to enable or disable wandering behavior of npcs
public class NPCActivationManager : MonoBehaviour
{
    public static NPCActivationManager Instance { get; private set; }
    [SerializeField] private float activationDistance = 25f; //maybe set to radius of beacon pulse
    [SerializeField] private float checkInterval = 0.5f; //dont run check logic every frame

    private Transform player;
    private List<NPCWander> npcs = new();
    private float timer;

    private void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this;
    }

    private void Start()
    {
        player = GameObject.FindGameObjectWithTag("Player").transform;
    }

    public void Register(NPCWander npc) => npcs.Add(npc);
    public void Unregister(NPCWander npc) => npcs.Remove(npc);

    private void Update()
    {
        timer += Time.deltaTime;
        if (timer < checkInterval) return;
        timer = 0f;

        float sqrThreshold = activationDistance * activationDistance;
        foreach (var npc in npcs)
        {
            float sqrDist = (npc.transform.position - player.position).sqrMagnitude; //actual distance takes sqrt so this is faster
            npc.SetActive(sqrDist <= sqrThreshold);
        }
    }
}
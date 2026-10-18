using UnityEngine;

//grabs wanderable npcs and registers them to the npcactivationmanager
public class NPC : MonoBehaviour
{
    private NPCWander wander;

    private void Start()
    {
        wander = GetComponent<NPCWander>();

        NPCManager.Instance.RegisterNPC();
        NPCActivationManager.Instance.Register(wander);
    }

    private void OnDestroy()
    {
        NPCActivationManager.Instance.Unregister(wander);
    }
}
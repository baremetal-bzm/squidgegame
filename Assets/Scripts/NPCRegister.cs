using UnityEngine;

public class NPCRegister : MonoBehaviour
{
    private void Start()
    {
        NPCManager.Instance.RegisterNPC();
    }
}
using UnityEngine;

public class PlayerEater : MonoBehaviour
{
    [SerializeField] private string npcTag = "NPC";
    [SerializeField] private string eatTriggerName = "Eat";
    [SerializeField] private AudioClip eatSound;

    private Animator animator;
    private AudioSource audioSource;

    private void Awake()
    {
        animator = GetComponentInChildren<Animator>();
        audioSource = GetComponent<AudioSource>();
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag(npcTag))
        {
            NPCManager.Instance.NPCEaten();
            animator.SetTrigger(eatTriggerName);
            audioSource.PlayOneShot(eatSound);
            Destroy(other.gameObject);
        }
    }
}
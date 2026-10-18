using UnityEngine;
using UnityEngine.Audio;
using UnityEngine.InputSystem;

public class BeaconActivator : MonoBehaviour
{
    public BeaconController beacon;
    public Key activationKey = Key.F;
    [SerializeField] private AudioClip clickSound;
    private AudioSource audioSource;

    void Awake()
    {
        if (beacon == null) beacon = FindAnyObjectByType<BeaconController>();
        audioSource = GetComponent<AudioSource>();
    }

    void Update()
    {
        if (Keyboard.current[activationKey].wasPressedThisFrame)
        {
            beacon.Activate(transform.position);
            audioSource.PlayOneShot(clickSound, 0.5f);
        }
    }
}
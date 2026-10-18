using UnityEngine;

//tracks alive/eaten squidge
public class NPCManager : MonoBehaviour
{
    public static NPCManager Instance { get; private set; }

    public int AliveCount { get; private set; }
    public int EatenCount { get; private set; }
    [SerializeField] private TMPro.TextMeshProUGUI countText;

    private void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this;
    }

    public void RegisterNPC()
    {
        AliveCount++;
        LogCounts();
    }

    public void NPCEaten()
    {
        AliveCount--;
        EatenCount++;
        LogCounts();
        GameFlowManager.Instance.CheckWinCondition(EatenCount);
    }

    private void LogCounts()
    {
        //Debug.Log($"NPCs Alive: {AliveCount} | Eaten: {EatenCount}");
        if (countText != null)
            countText.text = $"squidge till full {GameFlowManager.Instance.SquidsToWin - EatenCount}";
           // countText.text = $"Alive: {AliveCount}  Eaten: {EatenCount}";
    }
}
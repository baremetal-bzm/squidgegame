using UnityEngine;
using UnityEngine.SceneManagement;

public class GameFlowManager : MonoBehaviour
{
    public static GameFlowManager Instance { get; private set; }

    public enum GameState { Start, Playing, End }
    public GameState CurrentState { get; private set; } = GameState.Start;

    [Header("UI Panels")]
    [SerializeField] private GameObject startPanel;
    [SerializeField] private GameObject endPanel;
    [SerializeField] private GameObject hudPanel;

    [Header("Win Condition")]
    [SerializeField] private int squidsToWin = 10;
    public int SquidsToWin => squidsToWin;

    [Header("Player")]
    [SerializeField] private MonoBehaviour playerMovementScript; 

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
        EnterStartState();
    }

    private void EnterStartState()
    {
        CurrentState = GameState.Start;
        startPanel.SetActive(true);
        hudPanel.SetActive(false);
        endPanel.SetActive(false);
        playerMovementScript.enabled = false;
        Cursor.lockState = CursorLockMode.None;
        Cursor.visible = true;
    }

    // Hook this up to the "Play" buttons OnClick in the inspector
    public void StartGame()
    {
        CurrentState = GameState.Playing;
        startPanel.SetActive(false);
        hudPanel.SetActive(true);
        playerMovementScript.enabled = true;
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }

    // Called by NPCManager whenever an NPC is eaten
    public void CheckWinCondition(int eatenCount)
    {
        if (CurrentState != GameState.Playing) return;

        if (eatenCount >= squidsToWin)
        {
            EnterEndState();
        }
    }

    private void EnterEndState()
    {
        CurrentState = GameState.End;
        hudPanel.SetActive(false);
        endPanel.SetActive(true);
        playerMovementScript.enabled = false;
        Cursor.lockState = CursorLockMode.None;
        Cursor.visible = true;
    }

    // Hook this up to the "Restart" buttons OnClick in the inspector
    public void RestartGame()
    {
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
    }
}
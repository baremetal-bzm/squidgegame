using NUnit.Framework.Internal.Commands;
using UnityEngine;

public class NPCSpawner : MonoBehaviour
{
    [SerializeField] private GameObject npcPrefab;
    [SerializeField] private int spawnCount = 10;
    [SerializeField] private Vector2 spawnAreaSize = new Vector2(200f, 200f); // x and z dimensions of terrain/gamespace
    [SerializeField] private float minDepthAboveFloor = 1f; // don't spawn right on the terrain
    [SerializeField] private float maxHeight = 100f;

    private void Start()
    {
        for (int i = 0; i < spawnCount; i++)
        {
            SpawnNPC();
        }
    }

    private void SpawnNPC()
    {
        //be sure to place gameobject this script is attached to to center of spawning area, i.e. center of terrain object
        float randomX = transform.position.x + Random.Range(-spawnAreaSize.x / 2f, spawnAreaSize.x / 2f); 
        float randomZ = transform.position.z + Random.Range(-spawnAreaSize.y / 2f, spawnAreaSize.y / 2f);

        float floorY = Terrain.activeTerrain.SampleHeight(new Vector3(randomX, 0f, randomZ))
                       + Terrain.activeTerrain.transform.position.y; //worldspace height of terrain at that pt
        
        if (floorY >= maxHeight) return; //skip npc generation if the terrain goes higher than the max spawn height

        float lowerBound = floorY + minDepthAboveFloor;
        float upperBound = lowerBound+50f; //arbitrary value above terrain to allow them to spawn

        float randomY = Random.Range(lowerBound, upperBound);
        randomY = (randomY > maxHeight ? maxHeight : randomY); //clamp it below the max height
        Vector3 spawnPosition = new Vector3(randomX, randomY, randomZ);

        Instantiate(npcPrefab, spawnPosition, Quaternion.identity);
    }
}
import { jest } from '@jest/globals';

// ── Mock @azure/cosmos before importing the module under test ──────────────
const mockContainerCreate = jest.fn();
const mockDatabaseContainers = { createIfNotExists: mockContainerCreate };
const mockDatabases = { createIfNotExists: jest.fn() };
const mockCosmosClient = jest.fn();

jest.mock('@azure/cosmos', () => ({
  CosmosClient: mockCosmosClient,
}));

// ── Mock logger so we can assert on warn/info calls ───────────────────────
const mockLoggerWarn = jest.fn();
const mockLoggerInfo = jest.fn();

jest.mock('./logger', () => ({
  logger: { warn: mockLoggerWarn, info: mockLoggerInfo },
}));

// Helper: reset module registry so module-level state is fresh per test
async function freshImport() {
  jest.resetModules();

  // Re-apply mocks after resetModules
  jest.mock('@azure/cosmos', () => ({ CosmosClient: mockCosmosClient }));
  jest.mock('./logger', () => ({
    logger: { warn: mockLoggerWarn, info: mockLoggerInfo },
  }));

  return import('./database');
}

describe('database utils', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    delete process.env.COSMOS_ENDPOINT;
    delete process.env.COSMOS_KEY;
    delete process.env.COSMOS_DATABASE;
  });

  // ── isCosmosConfigured ─────────────────────────────────────────────────
  describe('isCosmosConfigured()', () => {
    it('should return false when env vars are missing', async () => {
      const { isCosmosConfigured } = await freshImport();
      expect(isCosmosConfigured()).toBe(false);
    });

    it('should return false when only COSMOS_ENDPOINT is set', async () => {
      process.env.COSMOS_ENDPOINT = 'https://example.documents.azure.com:443/';
      const { isCosmosConfigured } = await freshImport();
      expect(isCosmosConfigured()).toBe(false);
    });

    it('should return false when only COSMOS_KEY is set', async () => {
      process.env.COSMOS_KEY = 'test-key';
      const { isCosmosConfigured } = await freshImport();
      expect(isCosmosConfigured()).toBe(false);
    });

    it('should return true when both env vars are set', async () => {
      process.env.COSMOS_ENDPOINT = 'https://example.documents.azure.com:443/';
      process.env.COSMOS_KEY = 'test-key';
      const { isCosmosConfigured } = await freshImport();
      expect(isCosmosConfigured()).toBe(true);
    });
  });

  // ── initDatabase — missing credentials ────────────────────────────────
  describe('initDatabase() — no credentials', () => {
    it('should log a warning and return early when credentials are absent', async () => {
      const { initDatabase } = await freshImport();
      await initDatabase();
      expect(mockLoggerWarn).toHaveBeenCalledWith(
        expect.stringContaining('Cosmos DB credentials not configured'),
      );
      expect(mockCosmosClient).not.toHaveBeenCalled();
    });
  });

  // ── initDatabase — with credentials ───────────────────────────────────
  describe('initDatabase() — with credentials', () => {
    beforeEach(() => {
      process.env.COSMOS_ENDPOINT = 'https://example.documents.azure.com:443/';
      process.env.COSMOS_KEY = 'test-key';

      const mockTasksContainer = { id: 'tasks' };
      const mockTeamsContainer = { id: 'teams' };

      mockContainerCreate
        .mockResolvedValueOnce({ container: mockTasksContainer } as never)
        .mockResolvedValueOnce({ container: mockTeamsContainer } as never);

      const mockDb = { containers: { createIfNotExists: mockContainerCreate } };
      mockDatabases.createIfNotExists.mockResolvedValue({ database: mockDb } as never);
      mockCosmosClient.mockImplementation(() => ({ databases: mockDatabases }));
    });

    it('should create a CosmosClient with endpoint and key', async () => {
      const { initDatabase } = await freshImport();
      await initDatabase();
      expect(mockCosmosClient).toHaveBeenCalledWith({
        endpoint: 'https://example.documents.azure.com:443/',
        key: 'test-key',
      });
    });

    it('should create database using default id when COSMOS_DATABASE is unset', async () => {
      const { initDatabase } = await freshImport();
      await initDatabase();
      expect(mockDatabases.createIfNotExists).toHaveBeenCalledWith({ id: 'teamtasktracker' });
    });

    it('should use COSMOS_DATABASE env var when set', async () => {
      process.env.COSMOS_DATABASE = 'mydb';
      const { initDatabase } = await freshImport();
      await initDatabase();
      expect(mockDatabases.createIfNotExists).toHaveBeenCalledWith({ id: 'mydb' });
    });

    it('should create tasks and teams containers', async () => {
      const { initDatabase } = await freshImport();
      await initDatabase();
      expect(mockContainerCreate).toHaveBeenCalledWith({
        id: 'tasks',
        partitionKey: { paths: ['/teamId'] },
      });
      expect(mockContainerCreate).toHaveBeenCalledWith({
        id: 'teams',
        partitionKey: { paths: ['/id'] },
      });
    });

    it('should log info after successful connection', async () => {
      const { initDatabase } = await freshImport();
      await initDatabase();
      expect(mockLoggerInfo).toHaveBeenCalledWith(
        expect.objectContaining({ databaseId: expect.any(String) }),
        expect.stringContaining('Connected to Azure Cosmos DB'),
      );
    });

    it('should expose containers via getTasksContainer and getTeamsContainer', async () => {
      const { initDatabase, getTasksContainer, getTeamsContainer } = await freshImport();
      await initDatabase();
      expect(getTasksContainer()).toEqual({ id: 'tasks' });
      expect(getTeamsContainer()).toEqual({ id: 'teams' });
    });
  });

  // ── In-memory store ───────────────────────────────────────────────────
  describe('in-memory store', () => {
    it('should return a Map from getInMemoryTasks()', async () => {
      const { getInMemoryTasks } = await freshImport();
      expect(getInMemoryTasks()).toBeInstanceOf(Map);
    });

    it('should return a Map from getInMemoryTeams()', async () => {
      const { getInMemoryTeams } = await freshImport();
      expect(getInMemoryTeams()).toBeInstanceOf(Map);
    });

    it('should return the same Map instance on repeated calls', async () => {
      const { getInMemoryTasks, getInMemoryTeams } = await freshImport();
      expect(getInMemoryTasks()).toBe(getInMemoryTasks());
      expect(getInMemoryTeams()).toBe(getInMemoryTeams());
    });

    it('should allow storing and retrieving items', async () => {
      const { getInMemoryTasks } = await freshImport();
      const tasks = getInMemoryTasks();
      tasks.set('task-1', { id: 'task-1', title: 'Hello' });
      expect(tasks.get('task-1')).toEqual({ id: 'task-1', title: 'Hello' });
    });
  });
});

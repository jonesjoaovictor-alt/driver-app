/**
 * Banco de dados SQLite local para cache mínimo.
 *
 * Guarda somente o necessário para reabrir o app e reconciliar com o servidor:
 * - Uma única corrida ativa
 * - Fila limitada de posições GPS pendentes
 *
 * Nunca guarda nome/telefone do passageiro.
 * A cópia local nunca é fonte de verdade.
 *
 * Regras (MASTER_SPEC.md §13):
 * - Somente dados mínimos para recuperação.
 * - Nenhum dado pessoal do passageiro.
 * - Fila limitada, descartando leituras antigas.
 */

import * as SQLite from 'expo-sqlite';

const DB_NAME = 'driver_app.db';
const MAX_POSITION_QUEUE = 50;

let db: SQLite.SQLiteDatabase | null = null;

/**
 * Abre (ou cria) o banco SQLite local.
 */
export async function openDatabase(): Promise<SQLite.SQLiteDatabase> {
  if (db) {
    return db;
  }

  db = await SQLite.openDatabaseAsync(DB_NAME);
  await initSchema();
  return db;
}

/**
 * Cria as tabelas locais se não existirem.
 */
async function initSchema(): Promise<void> {
  if (!db) return;

  // Tabela da corrida ativa (apenas uma linha)
  await db.execAsync(`
    CREATE TABLE IF NOT EXISTS active_ride (
      id TEXT PRIMARY KEY,
      status TEXT NOT NULL,
      version INTEGER NOT NULL,
      driver_id TEXT,
      vehicle_id TEXT,
      pickup_latitude REAL NOT NULL,
      pickup_longitude REAL NOT NULL,
      pickup_label TEXT NOT NULL,
      destination_latitude REAL NOT NULL,
      destination_longitude REAL NOT NULL,
      destination_label TEXT NOT NULL,
      estimated_fare_cents INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      accepted_at TEXT,
      updated_at TEXT NOT NULL
    );
  `);

  // Fila limitada de posições GPS pendentes
  await db.execAsync(`
    CREATE TABLE IF NOT EXISTS position_queue (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      accuracy REAL,
      heading REAL,
      speed REAL,
      recorded_at TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
  `);

  // Índice para limpeza eficiente da fila antiga
  await db.execAsync(`
    CREATE INDEX IF NOT EXISTS idx_position_queue_created
    ON position_queue(created_at);
  `);
}

/**
 * Salva a corrida ativa no cache local. Substitui qualquer corrida anterior.
 */
export async function saveActiveRide(ride: {
  id: string;
  status: string;
  version: number;
  driver_id?: string | null;
  vehicle_id?: string | null;
  pickup_latitude: number;
  pickup_longitude: number;
  pickup_label: string;
  destination_latitude: number;
  destination_longitude: number;
  destination_label: string;
  estimated_fare_cents: number;
  created_at: string;
  accepted_at?: string | null;
  updated_at: string;
}): Promise<void> {
  const database = await openDatabase();

  // Remove qualquer corrida anterior (apenas uma ativa por vez)
  await database.runAsync('DELETE FROM active_ride');

  await database.runAsync(
    `INSERT INTO active_ride (
      id, status, version, driver_id, vehicle_id,
      pickup_latitude, pickup_longitude, pickup_label,
      destination_latitude, destination_longitude, destination_label,
      estimated_fare_cents, created_at, accepted_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      ride.id,
      ride.status,
      ride.version,
      ride.driver_id ?? null,
      ride.vehicle_id ?? null,
      ride.pickup_latitude,
      ride.pickup_longitude,
      ride.pickup_label,
      ride.destination_latitude,
      ride.destination_longitude,
      ride.destination_label,
      ride.estimated_fare_cents,
      ride.created_at,
      ride.accepted_at ?? null,
      ride.updated_at,
    ]
  );
}

/**
 * Lê a corrida ativa do cache local.
 */
export async function getActiveRideFromCache(): Promise<{
  id: string;
  status: string;
  version: number;
  driver_id: string | null;
  vehicle_id: string | null;
  pickup_latitude: number;
  pickup_longitude: number;
  pickup_label: string;
  destination_latitude: number;
  destination_longitude: number;
  destination_label: string;
  estimated_fare_cents: number;
  created_at: string;
  accepted_at: string | null;
  updated_at: string;
} | null> {
  const database = await openDatabase();
  const rows = await database.getAllAsync<{
    id: string;
    status: string;
    version: number;
    driver_id: string | null;
    vehicle_id: string | null;
    pickup_latitude: number;
    pickup_longitude: number;
    pickup_label: string;
    destination_latitude: number;
    destination_longitude: number;
    destination_label: string;
    estimated_fare_cents: number;
    created_at: string;
    accepted_at: string | null;
    updated_at: string;
  }>('SELECT * FROM active_ride LIMIT 1');

  return rows.length > 0 ? rows[0] : null;
}

/**
 * Remove a corrida ativa do cache local (apenas após confirmação do servidor).
 */
export async function clearActiveRideFromCache(): Promise<void> {
  const database = await openDatabase();
  await database.runAsync('DELETE FROM active_ride');
}

/**
 * Adiciona uma posição GPS à fila de pendentes.
 * Descarta as mais antigas se exceder o limite.
 */
export async function enqueuePosition(reading: {
  latitude: number;
  longitude: number;
  accuracy?: number | null;
  heading?: number | null;
  speed?: number | null;
  recorded_at: string;
}): Promise<void> {
  const database = await openDatabase();

  await database.runAsync(
    `INSERT INTO position_queue (
      latitude, longitude, accuracy, heading, speed, recorded_at
    ) VALUES (?, ?, ?, ?, ?, ?)`,
    [
      reading.latitude,
      reading.longitude,
      reading.accuracy ?? null,
      reading.heading ?? null,
      reading.speed ?? null,
      reading.recorded_at,
    ]
  );

  // Limpa a fila se exceder o limite, removendo as mais antigas
  const count = await database.getAllAsync<{ cnt: number }>(
    'SELECT COUNT(*) as cnt FROM position_queue'
  );

  if (count[0]?.cnt ?? 0 > MAX_POSITION_QUEUE) {
    const excess = (count[0]?.cnt ?? 0) - MAX_POSITION_QUEUE;
    await database.runAsync(
      `DELETE FROM position_queue WHERE id IN (
        SELECT id FROM position_queue ORDER BY created_at ASC LIMIT ?
      )`,
      [excess]
    );
  }
}

/**
 * Lê todas as posições pendentes da fila.
 */
export async function getPendingPositions(): Promise<Array<{
  id: number;
  latitude: number;
  longitude: number;
  accuracy: number | null;
  heading: number | null;
  speed: number | null;
  recorded_at: string;
  created_at: string;
}>> {
  const database = await openDatabase();
  return database.getAllAsync(
    'SELECT * FROM position_queue ORDER BY created_at ASC'
  );
}

/**
 * Remove posições já enviadas para o servidor.
 */
export async function clearSentPositions(upToId: number): Promise<void> {
  const database = await openDatabase();
  await database.runAsync('DELETE FROM position_queue WHERE id <= ?', [upToId]);
}

/**
 * Fecha a conexão com o banco.
 */
export async function closeDatabase(): Promise<void> {
  if (db) {
    await db.closeAsync();
    db = null;
  }
}

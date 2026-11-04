/**
 * Constantes do produto.
 *
 * Estes valores espelham o MASTER_SPEC.md. Eles servem à interface e às
 * mensagens ao usuário; a garantia real dos limites é do PostgreSQL
 * (spec §6 e §8). Nunca confie apenas nestes números para impedir algo.
 */

export const APP_NAME = 'DRIVER APP';

/** Spec §3: a administração é revelada por sete toques no logotipo. */
export const ADMIN_ACCESS_TAP_COUNT = 7;

/** Spec §6: máximo de motoristas cadastrados. */
export const MAX_DRIVERS = 5;

/** Spec §6: máximo de passageiros fictícios cadastrados. */
export const MAX_PASSENGERS = 5;

/** Spec §3: um único veículo ativo por motorista. */
export const MAX_ACTIVE_VEHICLES_PER_DRIVER = 1;

/** Spec §11: metas de intervalo de GPS, em milissegundos. */
export const GPS_INTERVAL_ONLINE_MS = 5_000;
export const GPS_INTERVAL_ON_RIDE_MS = 3_000;

/** Spec §8: sinal de vida enquanto online ou busy. */
export const HEARTBEAT_INTERVAL_MS = 30_000;

/** Spec §8: acima disso o servidor considera o motorista offline. */
export const HEARTBEAT_STALE_MS = 120_000;

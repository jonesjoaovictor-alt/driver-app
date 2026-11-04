/**
 * Tipos do banco de dados Supabase.
 *
 * Espelham as migrações em supabase/migrations/ (0001 a 0008).
 * Gerados manualmente a partir do schema SQL; mantê-los sincronizados com
 * as migrações sempre que o banco mudar.
 */

export type ProfileRole = 'admin' | 'driver';
export type DriverAvailability = 'offline' | 'online' | 'busy';
export type RideStatus = 'requested' | 'accepted' | 'driver_arriving' | 'arrived' | 'in_progress';
export type RideOperationType = 'accept' | 'arrive' | 'start' | 'complete' | 'cancel';
export type CancelActor = 'admin' | 'driver';

export interface Profile {
  id: string;
  auth_user_id: string;
  full_name: string;
  phone: string | null;
  role: ProfileRole;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  version: number;
}

export interface Driver {
  id: string;
  profile_id: string;
  is_active: boolean;
  availability: DriverAvailability;
  last_seen_at: string | null;
  created_at: string;
  updated_at: string;
  version: number;
}

export interface Vehicle {
  id: string;
  driver_id: string;
  brand: string;
  model: string;
  plate: string;
  color: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  version: number;
}

export interface Passenger {
  id: string;
  name: string;
  phone: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  version: number;
}

export interface ActiveRide {
  id: string;
  passenger_id: string;
  driver_id: string | null;
  vehicle_id: string | null;
  pickup_latitude: number;
  pickup_longitude: number;
  pickup_label: string;
  destination_latitude: number;
  destination_longitude: number;
  destination_label: string;
  estimated_fare_cents: number;
  status: RideStatus;
  created_at: string;
  accepted_at: string | null;
  arrived_at: string | null;
  started_at: string | null;
  cancelled_at: string | null;
  cancelled_by: CancelActor | null;
  cancel_reason: string | null;
  updated_at: string;
  version: number;
}

export interface RideOperation {
  id: string;
  ride_id: string;
  operation: RideOperationType;
  actor_profile_id: string;
  idempotency_key: string;
  created_at: string;
  expires_at: string;
}

export interface DriverLiveLocation {
  driver_id: string;
  latitude: number;
  longitude: number;
  accuracy: number | null;
  heading: number | null;
  speed: number | null;
  recorded_at: string;
  updated_at: string;
}

/**
 * Tipo genérico para tabelas do banco (útil para tipagem do Supabase client).
 */
export interface Database {
  public: {
    Functions: {
      accept_ride: {
        Args: {
          p_ride_id: string;
          p_idempotency_key: string;
          p_driver_id: string;
        };
        Returns: string;
      };
      mark_driver_arriving: {
        Args: {
          p_ride_id: string;
          p_driver_id: string;
        };
        Returns: string;
      };
      mark_arrived: {
        Args: {
          p_ride_id: string;
          p_driver_id: string;
        };
        Returns: string;
      };
      start_ride: {
        Args: {
          p_ride_id: string;
          p_driver_id: string;
        };
        Returns: string;
      };
      complete_ride: {
        Args: {
          p_ride_id: string;
          p_driver_id: string;
          p_idempotency_key: string;
        };
        Returns: string;
      };
      cancel_ride: {
        Args: {
          p_ride_id: string;
          p_driver_id: string;
          p_reason: string;
          p_actor: 'admin' | 'driver';
        };
        Returns: string;
      };
      list_available_rides: {
        Args: {};
        Returns: ActiveRide[];
      };
      set_availability: {
        Args: {
          p_availability: 'offline' | 'online' | 'busy';
        };
        Returns: void;
      };
      upsert_location: {
        Args: {
          p_latitude: number;
          p_longitude: number;
          p_accuracy: number | null;
          p_heading: number | null;
          p_speed: number | null;
          p_recorded_at: string;
        };
        Returns: void;
      };
      create_ride: {
        Args: {
          p_passenger_id: string;
          p_pickup_latitude: number;
          p_pickup_longitude: number;
          p_pickup_label: string;
          p_destination_latitude: number;
          p_destination_longitude: number;
          p_destination_label: string;
          p_estimated_fare_cents: number;
        };
        Returns: string;
      };
      create_driver: {
        Args: {
          p_profile_id: string;
        };
        Returns: string;
      };
      create_passenger: {
        Args: {
          p_name: string;
          p_phone: string | null;
        };
        Returns: string;
      };
      set_role: {
        Args: {
          p_profile_id: string;
          p_role: 'admin' | 'driver';
        };
        Returns: void;
      };
      create_driver_account: {
        Args: {
          p_auth_user_id: string;
          p_full_name: string;
          p_phone: string | null;
        };
        Returns: string;
      };
    };
    Tables: {
      profiles: {
        Row: Profile;
        Insert: Omit<Profile, 'created_at' | 'updated_at' | 'version'>;
        Update: Partial<Pick<Profile, 'full_name' | 'phone' | 'is_active' | 'role'>>;
      };
      drivers: {
        Row: Driver;
        Insert: Omit<Driver, 'created_at' | 'updated_at' | 'version'>;
        Update: Partial<Pick<Driver, 'is_active' | 'availability' | 'last_seen_at'>>;
      };
      vehicles: {
        Row: Vehicle;
        Insert: Omit<Vehicle, 'created_at' | 'updated_at' | 'version'>;
        Update: Partial<Pick<Vehicle, 'brand' | 'model' | 'plate' | 'color' | 'is_active'>>;
      };
      passengers: {
        Row: Passenger;
        Insert: Omit<Passenger, 'created_at' | 'updated_at' | 'version'>;
        Update: Partial<Pick<Passenger, 'name' | 'phone' | 'is_active'>>;
      };
      active_rides: {
        Row: ActiveRide;
        Insert: Omit<ActiveRide, 'created_at' | 'updated_at' | 'version'>;
        Update: Partial<
          Pick<ActiveRide, 'driver_id' | 'vehicle_id' | 'status' | 'accepted_at' | 'arrived_at' | 'started_at' | 'cancelled_at' | 'cancelled_by' | 'cancel_reason'>
        >;
      };
      ride_operations: {
        Row: RideOperation;
        Insert: Omit<RideOperation, 'id' | 'created_at' | 'expires_at'>;
        Update: never;
      };
      driver_live_locations: {
        Row: DriverLiveLocation;
        Insert: Omit<DriverLiveLocation, 'updated_at'>;
        Update: Partial<Pick<DriverLiveLocation, 'latitude' | 'longitude' | 'accuracy' | 'heading' | 'speed' | 'recorded_at'>>;
      };
    };
  };
}

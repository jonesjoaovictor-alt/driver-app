import {
  createContext,
  useContext,
  useEffect,
  useState,
  useCallback,
  ReactNode,
} from 'react';
import { supabase } from '../../services/supabase/client';
import type { Profile, Driver } from '../../types/database';

export interface AuthContextType {
  profile: Profile | null;
  driver: Driver | null;
  isLoading: boolean;
  signIn: (email: string, password: string) => Promise<{ error: string | null }>;
  signOut: () => Promise<void>;
  refreshDriver: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [driver, setDriver] = useState<Driver | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const loadSession = useCallback(async () => {
    try {
      const {
        data: { session },
      } = await supabase.auth.getSession();

      if (session?.user) {
        const { data: profData, error: profError } = await supabase
          .from('profiles')
          .select('*')
          .eq('auth_user_id', session.user.id)
          .single();

        if (profError || !profData) {
          setProfile(null);
          setDriver(null);
          return;
        }

        const prof = profData as Profile;
        setProfile(prof);

        if (prof.role === 'driver') {
          const { data: drvData, error: drvError } = await supabase
            .from('drivers')
            .select('*')
            .eq('profile_id', prof.id)
            .single();

          if (!drvError && drvData) {
            setDriver(drvData as Driver);
          }
        }
      } else {
        setProfile(null);
        setDriver(null);
      }
    } catch {
      setProfile(null);
      setDriver(null);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadSession();

    const { data: authListener } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
          await loadSession();
        } else if (event === 'SIGNED_OUT') {
          setProfile(null);
          setDriver(null);
          setIsLoading(false);
        }
      }
    );

    return () => {
      authListener.subscription.unsubscribe();
    };
  }, [loadSession]);

  const signIn = useCallback(
    async (email: string, password: string) => {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      if (error) {
        return { error: error.message };
      }
      await loadSession();
      return { error: null };
    },
    [loadSession]
  );

  const signOut = useCallback(async () => {
    await supabase.auth.signOut();
    setProfile(null);
    setDriver(null);
    setIsLoading(false);
  }, []);

  const refreshDriver = useCallback(async () => {
    if (!profile) return;
    const { data: drv, error: drvError } = await supabase
      .from('drivers')
      .select('*')
      .eq('profile_id', profile.id)
      .single();
    if (!drvError && drv) {
      setDriver(drv as Driver);
    }
  }, [profile]);

  return (
    <AuthContext.Provider
      value={{ profile, driver, isLoading, signIn, signOut, refreshDriver }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth deve ser usado dentro de um AuthProvider.');
  }
  return context;
}
